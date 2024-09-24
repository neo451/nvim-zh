local M = require "zh.jieba"

M.initialize()

local eq = assert.same

describe("DAG", function()
   it("should return DAG", function()
      eq({}, M.get_DAG "")
      eq({ { 1, 2 }, { 2 }, { 3 } }, M.get_DAG "你好w")
      eq({ { 1 }, { 2 }, { 3, 4 }, { 4 }, { 5, 6, 7 }, { 6 }, { 7 } }, M.get_DAG "我爱北京天安门")
   end)
end)

describe("calc", function()
   it("should calc correct path for in dict words", function()
      local dag = M.get_DAG "我爱北京天安门"
      eq({ 1, 2, 4, 4, 7, 6, 7, 0 }, M.calc("我爱北京天安门", dag))
   end)
end)

describe("cut_no_hmm", function()
   it("should cut with hidden markov algo", function()
      local target = { "我", "爱", "北京", "天安门" }
      local index = 1
      for word in M.cut_no_hmm "我爱北京天安门" do
         eq(target[index], word)
         index = index + 1
      end
   end)
end)
