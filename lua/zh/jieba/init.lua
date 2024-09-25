local ut = require "zh.utils"
local hmm = require "zh.jieba.hmm"

local str_match = string.match
local log = math.log
local len = vim.fn.strchars
local sub = ut.sub

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

local function cut_hmm(sentence)
   local route, N = calc(sentence)
   local x = 1
   local buf = ""
   local res = {}
   while x <= N do
      local y = route[x]
      local l_word = sub(sentence, x, y)
      if y == x then
         buf = buf .. l_word
      else
         if buf ~= "" then
            if len(buf) == 1 then
               res[#res + 1] = buf
               buf = ""
            elseif not M.dict[buf] then
               local recognized = hmm.cut(buf)
               for _, word in ipairs(recognized) do
                  res[#res + 1] = word
               end
            else
               for _, word in codes(buf) do
                  res[#res + 1] = word
               end
            end
            buf = ""
         end
         res[#res + 1] = l_word
      end
      x = y + 1
   end

   if buf ~= "" then
      if len(buf) == 1 then
         res[#res + 1] = buf
      elseif not M.dict[buf] then
         local recognized = hmm.cut(buf)
         for _, word in ipairs(recognized) do
            res[#res + 1] = word
         end
      else
         for _, word in codes(buf) do
            res[#res + 1] = word
         end
      end
   end
   return res
end

M.lcut = function(sentence, HMM)
   local res = {}
   local cutfunc
   if HMM then
      cutfunc = cut_hmm
   else
      cutfunc = M.cut_no_hmm
   end
   local blocks = ut.split_string(sentence)
   for _, v in ipairs(blocks) do
      -- TODO: check iff zh, then use cutfunc
      for word in cutfunc(v) do
         print(word)
         res[#res + 1] = word
      end
   end
   return res
end

M.cut = function(sentence)
   return vim.iter(M.lcut(sentence))
end

-- Pr(vim.iter(M.cut_no_hmm "你好世界123"):totable())

-- for v in M.cut "你好世界123" do
--    print(v)
-- end
--
return M
