local ut = require("jieba.utils")
local hmm = require("jieba.hmm")

local str_match = string.match
local log = math.log
local len = vim.fn.strchars

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
	local dict = require("jieba.dict") or gen_pfdict("data/dict.txt")
	M.dict = dict
	-- HACK:
	for word, v in pairs(M.dict) do
		M.dict[word] = log(v) - M.logtotal
	end
	print(("jieba-lua initialized in %s"):format(os.clock() - t))
end

local get_DAG = function(sentence)
	local DAG = {}
	local N = vim.fn.strchars(sentence)
	local frag = ""
	for k = 1, N do
		DAG[k] = {}
		local i = k
		frag = ut.sub(sentence, k, k)
		while i <= N and M.dict[frag] do
			DAG[k][#DAG[k] + 1] = i
			i = i + 1
			frag = ut.sub(sentence, k, i)
		end
		if #DAG[k] == 0 then
			DAG[k][1] = k
		end
	end
	return DAG
end
M.get_DAG = get_DAG

local calc = function(sentence, DAG)
	local N = vim.fn.strchars(sentence)
	local route = {}
	route[N + 1] = { 0, 0 }
	for i = N, 1, -1 do
		local tmp_list = {}
		for j = 1, #DAG[i] do
			local x = DAG[i][j]
			tmp_list[#tmp_list + 1] = { (M.dict[ut.sub(sentence, i, x)] or 0) + route[x + 1][1], x }
			-- print(tmp_list[#tmp_list][1])
		end
		table.sort(tmp_list, function(a, b)
			return a[1] > b[1]
		end)
		route[i] = tmp_list[1]
	end
	return vim.iter(route):fold({}, function(acc, k)
		acc[#acc + 1] = k[2]
		return acc
	end)
end
M.calc = calc

local function cut_all(sentence)
	local DAG = get_DAG(sentence)
	local old_j = -1
	local k, v = 0, nil
	local v_index = 0
	return function()
		while k <= #DAG do
			-- When we need to move to the next set of end positions or start the loop
			if not v or v_index >= #v then
				k = k + 1
				if k > #DAG then
					return nil
				end -- End of DAG, stop iteration
				v = DAG[k]

				v_index = 1
			else
				v_index = v_index + 1 -- Move to the next end position in the current set
			end
			if #v == 1 and k > old_j then
				old_j = v[1]
				return ut.sub(sentence, k, v[1])
			end
			for i = v_index, #v do
				local j = v[i]
				if j > k and j > old_j then -- Ensure non-overlapping segments
					old_j = j -- Update the last used endpoint
					v_index = i -- Update v_index for the next iteration
					return ut.sub(sentence, k, j) -- Using native Lua substring operation
				end
			end
		end
	end
end

function M.cut_no_hmm(sentence)
	local DAG = get_DAG(sentence)
	local route = calc(sentence, DAG)
	local x = 1
	local N = vim.fn.strchars(sentence)
	local buf = ""

	return function()
		while x <= N do
			local y = route[x]
			local l_word = ut.sub(sentence, x, y)
			if vim.fn.strchars(l_word) == 1 and ut.is_eng(l_word) then
				buf = buf .. l_word
				x = y + 1
			else
				if #buf > 0 then
					local result = buf
					buf = ""
					x = x + 1
					return result
				end
				x = y + 1
				return l_word
			end
		end
		if #buf > 0 then
			local result = buf
			buf = ""
			return result
		end
	end
end

local function cut_hmm(sentence)
	local DAG = get_DAG(sentence)
	local route = calc(sentence, DAG)
	local x = 1
	local N = len(sentence)
	local buf = ""
	local res = {}
	while x <= N do
		local y = route[x][2]
		local l_word = ut.sub(sentence, x, y)
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

M.lcut = function(sentence, all, HMM)
	local res = {}
	local cutfunc
	if all then
		cutfunc = cut_all
	elseif HMM then
		cutfunc = cut_hmm
	else
		cutfunc = M.cut_no_hmm
	end
	local blocks = ut.split_similar_char(sentence)
	for _, v in ipairs(blocks) do
		for word in cutfunc(v) do
			res[#res + 1] = word
		end
	end
	return res
end

return M
