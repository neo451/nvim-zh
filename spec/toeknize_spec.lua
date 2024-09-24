local ut = require "zh.utils"

local eq = assert.same

describe("strchars", function()
   it("should return correct amount of zh-chars", function()
      eq(7, vim.fn.strchars "你好world")
   end)

   it("should iterate all zh-chars", function()
      local target = { "你", "好", "w", "o", "r", "l", "d" }
      for num, word in ut.zsplit "你好world" do
         eq(target[num], word)
      end
   end)

   it("should do string sub aware of utf8", function()
      eq("你", ut.sub("你好world", 1, 1))
      eq("你好", ut.sub("你好world", 1, 2))
      eq("你好wo", ut.sub("你好world", 1, 4))
   end)
end)
describe("split_string", function()
   it("should split neighbouring str with same type", function()
      eq("western", ut.type "hello")
      assert.is_false(pcall(ut.type, "hello!"))
      eq({ "你好", "world", "123" }, ut.split_string "你好world123")
   end)
end)
