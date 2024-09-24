local M = {}
local MIN_FLOAT = -3.14e100
local start = require "zh.jieba.prob_start"
local emit = require "zh.jieba.prob_emit"
local trans = require "zh.jieba.prob_trans"
local ut = require "zh.utils"

-- add forcesplit
-- fix the better version
-- local function viterbi(obs, states, start_p, trans_p, emit_p)
-- 	local V = { {} } -- tabular
-- 	local prev_best_state = {} -- optimized space usage
-- 	for _, y in pairs(states) do -- init
-- 		V[1][y] = start_p[y] + (emit_p[y][obs[1]] or MIN_FLOAT)
-- 		prev_best_state[y] = {}
-- 	end
--
-- 	for t = 2, #obs do
-- 		V[t] = {}
-- 		for _, y in pairs(states) do
-- 			local em_p = (emit_p[y][obs[t]] or MIN_FLOAT)
-- 			local max_prob = MIN_FLOAT
-- 			local best_prev_state
--
-- 			for _, y0 in pairs(states) do
-- 				local tr_p = trans_p[y0][y] or MIN_FLOAT
-- 				local prob0 = V[t - 1][y0] + tr_p + em_p
-- 				if prob0 > max_prob then
-- 					max_prob = prob0
-- 					best_prev_state = y0
-- 				end
-- 			end
--
-- 			V[t][y] = max_prob
-- 			prev_best_state[y][t] = best_prev_state
-- 		end
-- 	end
--
-- 	-- Find the most probable final state
-- 	local max_prob = MIN_FLOAT
-- 	local best_final_state
--
-- 	for _, y in pairs(states) do
-- 		if V[#obs][y] > max_prob then
-- 			max_prob = V[#obs][y]
-- 			best_final_state = y
-- 		end
-- 	end
--
-- 	-- Build and return the most probable path
-- 	local most_probable_path = { best_final_state }
-- 	local current_best_state = best_final_state
--
-- 	for t = #obs, 2, -1 do
-- 		current_best_state = prev_best_state[current_best_state][t]
-- 		table.insert(most_probable_path, 1, current_best_state)
-- 	end
--   print(vim.inspect(most_probable_path))
-- 	return most_probable_path
-- end
local PrevStatus = {
   ["B"] = { "E", "S" },
   ["M"] = { "M", "B" },
   ["S"] = { "S", "E" },
   ["E"] = { "B", "M" },
}

local function viterbi(obs, states, start_p, trans_p, emit_p)
   local V = { {} } -- tabular
   local path = {}
   for _, y in pairs(states) do -- init
      V[1][y] = start_p[y] + (emit_p[y][obs[1]] or MIN_FLOAT)
      path[y] = { y }
   end
   for t = 2, #obs do
      V[t] = {}
      local newpath = {}
      for _, y in pairs(states) do
         local em_p = (emit_p[y][obs[t]] or MIN_FLOAT)
         local prob, state = nil, PrevStatus[y][1]
         local max_prob = MIN_FLOAT
         for _, y0 in pairs(PrevStatus[y]) do
            local tr_p = trans_p[y0][y] or MIN_FLOAT
            local prob0 = V[t - 1][y0] + tr_p + em_p
            if prob0 > max_prob then
               max_prob = prob0
               state = y0
            end
         end
         prob = max_prob
         V[t][y] = prob
         newpath[y] = {}
         for _, p in pairs(path[state]) do
            table.insert(newpath[y], p)
         end
         table.insert(newpath[y], y)
      end
      path = newpath
   end

   local prob, state = nil, "E"
   local max_prob = MIN_FLOAT
   for _, y in pairs { "E", "S" } do
      if V[#obs][y] > max_prob then
         max_prob = V[#obs][y]
         state = y
      end
   end
   prob = max_prob
   return prob, path[state]
end

local function cut(sentence, start_p, trans_p, emit_p)
   local str = ut.split_char(sentence)
   local _, pos_list = viterbi(str, { "B", "M", "E", "S" }, start_p, trans_p, emit_p)
   local result = {}
   local begin, nexti = 1, 1
   local sentence_length = #str
   for i = 1, sentence_length do
      local char = str[i]
      local pos = pos_list[i]
      if pos == "B" then
         begin = i
      elseif pos == "E" then
         local res = {}
         for _, v in pairs { unpack(str, begin, i) } do
            res[#res + 1] = v
         end
         local val = table.concat(res)
         result[#result + 1] = val
         nexti = i + 1
      elseif pos == "S" then
         result[#result + 1] = char
         nexti = i + 1
      end
   end
   if nexti <= sentence_length then
      result[#result] = str[nexti]
   end
   return result
end

local function cut_iter(sentence)
   local str = ut.split_char(sentence)
   local _, pos_list = viterbi(str, { "B", "M", "E", "S" }, start, trans, emit)
   local sentence_length = #str
   -- local state = 1

   local function iter(param, state)
      local begin, nexti = state, state
      while nexti <= sentence_length do
         local char = str[nexti]
         local pos = pos_list[nexti]
         if pos == "B" then
            begin = nexti
            nexti = nexti + 1
         elseif pos == "E" then
            local res = {}
            for i = begin, nexti do
               table.insert(res, str[i])
            end
            coroutine.yield(table.concat(res))
            nexti = nexti + 1
         -- return table.concat(res)
         elseif pos == "S" then
            coroutine.yield(char)
            nexti = nexti + 1
         -- return char
         else -- For 'M' and handling continuous 'B' without an 'E' which is unlikely but safer to handle.
            nexti = nexti + 1
         end
         if begin < nexti and nexti > sentence_length then
            -- Handling case if the last word in the sentence ends with 'B' or 'M'
            local res = {}
            for i = begin, nexti - 1 do
               table.insert(res, str[i])
            end
            if #res > 0 then
               -- return table.concat(res)
               coroutine.yield(table.concat(res))
            end
         end
      end
   end

   return coroutine.wrap(function()
      iter(str, 1)
   end)
   -- return iter
end

-- -- Example usage:
-- for word in cut_iter("南京市长江大桥") do
--    print(word)
-- end

-- local Force_Split_Words = {}

function M.cut(sentence)
   local blocks = ut.split_string(sentence)
   local result = {}
   for _, blk in ipairs(blocks) do
      if ut.is_chinese(blk) then
         -- local l = M.lcut(blk)
         -- for _, word in pairs(l) do
         --    result[#result + 1] = word
         -- end
         for word in cut_iter(blk) do
            result[#result + 1] = word
         end
      else
         print(blk)
         for _, word in pairs(ut.split_string(blk)) do
            result[#result + 1] = word
         end
      end
   end
   return result
end

return M
