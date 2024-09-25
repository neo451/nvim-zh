local ut = require "zh.utils"
local hmm = require "zh.jieba.hmm"

local str_match = string.match
local log = math.log
local len = vim.fn.strchars
local sub = ut.sub
local zsplit = ut.zsplit

local M = {
   initialized = false,
   dict = {},
   logtotal = log(60101967), -- HACK: magic number!
}

local gen_pfdict = function(file)
   local f = io.open(file, "r")
   if f == nil then
      return
   end
   for line in f:lines() do
      local word, freq = str_match(line, "(%S+)%s(%d+)")
      M.dict[word] = log(freq) - M.logtotal
   end
   f:close()
end

M.initialize = function()
   local t = os.clock()
   local dict = require "zh.jieba.dict" or gen_pfdict "data/dict.txt"
   M.dict = dict
   -- HACK:
   for word, v in pairs(M.dict) do
      M.dict[word] = log(v) - M.logtotal
   end
   print(("jieba-lua initialized in %s"):format(os.clock() - t))
end

local get_DAG = function(sentence)
   local DAG, N = {}, len(sentence)
   for k = 1, N do
      local t = {}
      for j = k, N do
         local frag = sub(sentence, k, j)
         if M.dict[frag] then
            t[#t + 1] = j
         end
      end
      DAG[k] = (#t == 0) and { k } or t
   end
   return DAG
end
M.get_DAG = get_DAG

---return route of sentence
---@param sentence string
---@return table
local calc = function(sentence)
   local DAG = get_DAG(sentence)
   local N = len(sentence)
   local route = {
      [N + 1] = { 0, 0 },
   }
   for i = N, 1, -1 do
      local t = {}
      for j = 1, #DAG[i] do
         local x = DAG[i][j]
         t[#t + 1] = { (M.dict[sub(sentence, i, x)] or 0) + route[x + 1][1], x }
      end
      table.sort(t, function(a, b)
         return a[1] > b[1]
      end)
      route[i] = t[1]
   end
   route[N + 1] = nil
   return vim.iter(route):fold({}, function(acc, k)
      acc[#acc + 1] = k[2]
      return acc
   end)
end
M.calc = calc

---split sentence by dict, input must be zh-sentence
---@param sentence any
---@return function
---@return table
---@return integer
function M.cut_no_hmm(sentence)
   local f = function(route, i)
      i = i + 1
      if i > #route then
         return nil
      end
      local pos = route[i]
      return pos, sub(sentence, i, pos)
   end
   return f, calc(sentence), 0
end

---split sentence by hmm, input must be zh-sentence
---@param sentence string
function M.cut_hmm(sentence)
   local route = calc(sentence)
   local x = 1
   local n = 0
   local buf = ""
   return coroutine.wrap(function()
      while x <= #route do
         local y = route[x]
         local l_word = sub(sentence, x, y)
         if y == x then
            buf = buf .. l_word
         else
            if buf ~= "" then
               if len(buf) == 1 then
                  n = n + 1
                  coroutine.yield(n, buf)
                  buf = ""
               elseif not M.dict[buf] then
                  for word in hmm.cut(buf) do
                     n = n + 1
                     coroutine.yield(n, word)
                  end
               else
                  for word in zsplit(buf) do
                     n = n + 1
                     coroutine.yield(n, word)
                  end
               end
               buf = ""
            end
            n = n + 1
            coroutine.yield(n, l_word)
         end
         x = y + 1
      end
   end)
end

M.cut = function(sentence, HMM)
   local cutfunc
   if HMM then
      cutfunc = M.cut_hmm
   else
      cutfunc = M.cut_no_hmm
   end
   local blocks = ut.parse(sentence)
   return vim.iter(coroutine.wrap(function()
      local idx = 0
      for i, v in ipairs(blocks.content) do
         if blocks.type[i] == "hans" then
            for _, word in cutfunc(v) do
               idx = idx + 1
               coroutine.yield(idx, word)
            end
         else
            idx = idx + 1
            coroutine.yield(idx, blocks.content[i])
         end
      end
   end))
end

return M
