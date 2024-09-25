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
   return path[state]
end

local function __cut(sentence)
   local str = ut.split_char(sentence)
   local pos_list = viterbi(str, { "B", "M", "E", "S" }, start, trans, emit)
   local begin = 1
   local f = function(list, i)
      i = i + 1
      while i <= #str do
         local char = str[i]
         local T = list[i]
         if T == "B" then
            begin = i
         elseif T == "E" then
            local buf = {}
            for j = begin, i do
               buf[#buf + 1] = str[j]
            end
            return i, table.concat(buf, "")
         elseif T == "S" then
            return i, char
         end
         i = i + 1
      end
   end
   return f, pos_list, 0
end

-- print(vim.iter(cut "韩冰是好人"):next())

---comment
---@param sentence string
---@return Iter
function M.cut(sentence)
   local index = 0
   return vim.iter(__cut(sentence)):map(function(_, v)
      index = index + 1
      return v, index
   end)
end

return M
