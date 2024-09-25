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
      eq({ 1, 2, 4, 4, 7, 6, 7 }, M.calc "我爱北京天安门")
   end)
end)

describe("cut_no_hmm", function()
   it("should cut without hidden markov algo", function()
      local target = { "我", "爱", [4] = "北京", [7] = "天安门" }
      for num, word in M.cut_no_hmm "我爱北京天安门" do
         eq(target[num], word)
      end
   end)
end)

describe("cut_hmm", function()
   it("should cut with hidden markov algo", function()
      local target = { "韩冰", "是", "好人" }
      for num, word in M.cut_hmm "韩冰是好人" do
         eq(target[num], word)
      end
   end)
end)

describe("cut_hmm", function()
   it("should cut with hidden markov algo", function()
      local target = { "world", "韩冰", "是", "好人", ":'", "：“”" }
      for num, word in M.cut("world韩冰是好人:'：“”", true) do
         eq(target[num], word)
      end
   end)
end)
