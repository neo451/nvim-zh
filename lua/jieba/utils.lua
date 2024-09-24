local M = {}
local utf8 = require("jieba.utf8")
local lpeg = require("lpeg") or vim.lpeg

local spaces = lpeg.C(lpeg.S(" \t\n") ^ 1)
local hans = lpeg.C(lpeg.utfR(0x4E00, 0x9FFF) ^ 1) -- 0x9FA5?
local engs = lpeg.C(lpeg.R("az", "AZ") ^ 1)
local half_punc = lpeg.C(lpeg.S("·.,;!?()[]{}+-=_!@#$%^&*~`'\"<>:|\\"))
local nums = lpeg.C(lpeg.R("09") ^ 1)
local full_punc = lpeg.C(lpeg.utfR(0x3000, 0x303F) + lpeg.utfR(0xFF01, 0xFF5E) + lpeg.utfR(0x2000, 0x206F)) -- 0xFF01 to 0xFF5E

local p_str = lpeg.Ct((hans + engs + half_punc + full_punc + nums + spaces) ^ 0)

function M.split_string(str)
	return p_str:match(str)
end

M.is_eng = function(char)
	if string.find(char, "[a-zA-Z0-9]") then
		return true
	else
		return false
	end
end

-- 不一定全
function M.is_punctuation(c)
	local code = utf8.codepoint(c)
	-- 全角标点符号的 Unicode 范围为：0x3000-0x303F, 0xFF00-0xFFFF
	return (code >= 0x3000 and code <= 0x303F) or (code >= 0xFF00 and code <= 0xFFFF)
end

function M.is_chinese_char(c)
	local code = utf8.codepoint(c)
	return (code >= 0x4E00 and code <= 0x9FA5)
end

function M.is_chinese(sentence)
	local tmp = true
	for i in string.gmatch(sentence, "[%z\1-\127\194-\244][\128-\191]*") do
		if not M.is_chinese_char(i) then
			tmp = tmp and false
		else
			tmp = tmp and true
		end
	end
	return tmp
end

function M.split_similar_char(s)
	local t = {} -- 创建一个table用来储存分割后的字符
	local currentString = ""
	local previousIsChinese = nil

	for i = 1, utf8.len(s) do -- 迭代整个字符串
		-- local c = utf8.sub(s, i, i) -- 求出第i个字符
		local c = M.sub(s, i, i) -- 求出第i个字符
		local isChinese = M.is_chinese_char(c) --  判断是否是中文字符
		if previousIsChinese == nil or isChinese == previousIsChinese then
			currentString = currentString .. c
		else
			-- 添加先前的字符串
			if currentString ~= "" then
				table.insert(t, currentString)
				currentString = ""
			end
			currentString = c
		end
		previousIsChinese = isChinese
	end
	-- 添加最后的字符串（如存在）
	if currentString ~= "" then
		table.insert(t, currentString)
	end
	return t -- 返回含有所有字符串的table
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
