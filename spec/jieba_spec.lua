local M = require("jieba")
local ut = require("jieba.utils")

M.initialize()

local eq = assert.same

describe("strchars", function()
	it("should return correct amount of zh-chars", function()
		eq(7, vim.fn.strchars("你好world"))
	end)

	it("should iterate all zh-chars", function()
		local target = { "你", "好", "w", "o", "r", "l", "d" }
		for num, word in ut.zsplit("你好world") do
			eq(target[num], word)
		end
	end)

	it("should do string sub aware of utf8", function()
		eq("你", ut.sub("你好world", 1, 1))
		eq("你好", ut.sub("你好world", 1, 2))
		eq("你好wo", ut.sub("你好world", 1, 4))
	end)
end)

describe("DAG", function()
	it("should return DAG", function()
		eq({}, M.get_DAG(""))
		eq({ { 1, 2 }, { 2 }, { 3 } }, M.get_DAG("你好w"))
		eq({ { 1 }, { 2 }, { 3, 4 }, { 4 }, { 5, 6, 7 }, { 6 }, { 7 } }, M.get_DAG("我爱北京天安门"))
	end)
end)

describe("calc", function()
	it("should calc correct path for in dict words", function()
		local dag = M.get_DAG("我爱北京天安门")
		eq({ 1, 2, 4, 4, 7, 6, 7, 0 }, M.calc("我爱北京天安门", dag))
	end)
end)

describe("cut_no_hmm", function()
	it("should cut with hidden markov algo", function()
		local target = { "我", "爱", "北京", "天安门" }
		local index = 1
		for word in M.cut_no_hmm("我爱北京天安门") do
			eq(target[index], word)
			index = index + 1
		end
	end)
end)
