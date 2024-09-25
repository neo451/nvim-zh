local M = require "zh.motion"

TokenType = { hans = 1, punc = 2, space = 3, non_word = 4 }

describe("get_token_type", function()
   it("should get 4 types", function()
      assert.same(TokenType.hans, M.get_token_type "你好")
      assert.same(TokenType.punc, M.get_token_type ",")
      assert.same(TokenType.punc, M.get_token_type "。")
      assert.same(TokenType.space, M.get_token_type " ")
      assert.same(TokenType.space, M.get_token_type " ")
      assert.same(TokenType.space, M.get_token_type "\t")
      assert.same(TokenType.space, M.get_token_type "\n")
   end)
end)
