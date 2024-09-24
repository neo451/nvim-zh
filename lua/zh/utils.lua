local M = {}

local lpeg = vim.lpeg
local C, S, utfR, R = lpeg.C, lpeg.S, lpeg.utfR, lpeg.R

-- 字符集	字数	Unicode 编码
-- 基本汉字	20902字	4E00-9FA5
-- 基本汉字补充	38字	9FA6-9FCB
-- 扩展A	6582字	3400-4DB5
-- 扩展B	42711字	20000-2A6D6
-- 扩展C	4149字	2A700-2B734
-- 扩展D	222字	2B740-2B81D
-- 康熙部首	214字	2F00-2FD5
-- 部首扩展	115字	2E80-2EF3
-- 兼容汉字	477字	F900-FAD9
-- 兼容扩展	542字	2F800-2FA1D
-- PUA(GBK)部件	81字	E815-E86F
-- 部件扩展	452字	E400-E5E8
-- PUA增补	207字	E600-E6CF
-- 汉字笔画	36字	31C0-31E3
-- 汉字结构	12字	2FF0-2FFB
-- 汉语注音	22字	3105-3120
-- 注音扩展	22字	31A0-31BA
-- 〇	1字	3007
-- 数字0-9	10字	30-39
-- 小写英文字母	26字	61-7a
-- 大写英文字母	26字	41-5a

---@alias ZhType string # TODO:

---@class ZhState
---@field start integer
---@field type ZhType
---@field content string # TODO: maybe removed once there is effective solution to get with range

local L = {
   start = { 0 },
   type = {},
   content = {},
}

local function updateL(name)
   return function(tok)
      print(tok)
      L.start[#L.start + 1] = #tok + L.start[#L.start]
      L.type[#L.type + 1] = name
      L.content[#L.content + 1] = tok
   end
end

-- not all...
local hans = C(utfR(0x4E00, 0x9FFF) ^ 1) / updateL "hans"
-- 0x9FA5?
local half_punc = C(S "·.,;!?()[]{}+-=_!@#$%^&*~`'\"<>:|\\" ^ 1) / updateL "halfwidth"

local full_punc = (utfR(0x3000, 0x303F) + utfR(0xFF01, 0xFF5E) + utfR(0x2000, 0x206F)) ^ 1 / updateL "fullwidth"

local full_num = C(utfR(0xFF10, 0xFF19) ^ 1) / updateL "full_number"

local engs = C(R("az", "AZ") ^ 1) / updateL "western"

--- TODO: make more robust
local nums = C(R "09" ^ 1) / updateL "number"

local space = C(S " \t\n" ^ 1) / updateL "space"

local rules = (full_num + nums + engs + full_punc + half_punc + hans + space) ^ 1

---@param str string
---@return table
function M.parse(str)
   --check no \n
   rules:match(str)
   local retL = L
   L = { start = { 0 }, type = {}, content = {} }
   return retL
end

function M.split_string(str)
   return M.parse(str).content
end

---@param str string
---@return ZhType
M.type = function(str)
   local types = M.parse(str).type
   if #types ~= 1 then
      error "did not pass a mono-type string into str-type"
   else
      return types[1]
   end
end

---@param c string
---@return boolean
function M.is_eng(c)
   return M.type(c) == "western"
end
---@param c string
---@return boolean
function M.is_punctuation(c)
   return (M.type(c) == "fullwidth") or (M.type(c) == "halfwidth")
end

local p = "[%z\1-\127\194-\244][\128-\191]*"

M.zsplit = function(str)
   return vim.iter(string.gmatch(str, p)):enumerate()
end

---@return string
M.sub = function(str, startChar, endChar)
   local res = M.zsplit(str)
      :filter(function(i, _)
         return (i >= startChar) and (i <= endChar)
      end)
      :fold({}, function(acc, _, v)
         acc[#acc + 1] = v
         return acc
      end)
   return table.concat(res, "")
end

M.split_char = function(str)
   return M.zsplit(str):fold({}, function(acc, k, v)
      acc[k] = v
      return acc
   end)
end

return M
