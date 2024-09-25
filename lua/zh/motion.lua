-- TODO: only load in certain filetypes
local M = {}
local jieba = require "zh.jieba"
jieba.initialize()

local ut = require "zh.utils"

local sub = ut.sub
local len = vim.fn.strchars

-- TokenType Enum
TokenType = { hans = 1, punc = 2, space = 3, non_word = 4 }

local function get_token_type(str)
   local T = ut.type(str)
   if T == "space" then
      return TokenType.space
   elseif T == "fullwidth" or T == "halfwidth" then
      return TokenType.punc
   elseif T == "hans" then
      return TokenType.hans
   else
      return TokenType.non_word
   end
end
M.get_token_type = get_token_type

-- Parse each token as a table {i, j, t} such that i denotes the byte index of the first
-- character of the token, j denotes the byte index of the last character of the token,
-- t denotes the type of the token. If j is less than i, it means that the underlying
-- token is an empty string.
local function parse_tokens(tokens)
   local cum_l = 0
   local parsed = {}
   for _, tok in ipairs(tokens) do
      local i = cum_l
      cum_l = cum_l + #tok
      local j = cum_l - #sub(tok, len(tok), len(tok))
      parsed[#parsed + 1] = { i = i, j = j, t = get_token_type(tok) }
   end
   return parsed
end

local function _gen_implicit_space_in_between(parsed_tok2)
   local i2 = parsed_tok2.i
   return { i = i2, j = i2 - 1, t = TokenType.space }
end

local function insert_implicit_space_rule(parsed_tok1, parsed_tok2)
   if parsed_tok1 == nil then
      return nil
   end
   local rules = {
      [TokenType.hans] = {
         [TokenType.hans] = true,
         [TokenType.punc] = false,
         [TokenType.space] = false,
         [TokenType.non_word] = false,
      },
      [TokenType.punc] = {
         [TokenType.hans] = true,
         [TokenType.punc] = true,
         [TokenType.space] = false,
         [TokenType.non_word] = true,
      },
      [TokenType.space] = {
         [TokenType.hans] = false,
         [TokenType.punc] = false,
         [TokenType.space] = false,
         [TokenType.non_word] = false,
      },
      [TokenType.non_word] = {
         [TokenType.hans] = false,
         [TokenType.punc] = false,
         [TokenType.space] = false,
         [TokenType.non_word] = false,
      },
   }
   local t1 = rules[parsed_tok1.t][parsed_tok2.t]
   if t1 then
      local imp_space = _gen_implicit_space_in_between(parsed_tok2)
      return { parsed_tok1, imp_space, parsed_tok2 }
   end
   return nil
end

local function stack_merge(elements)
   local stack = {}
   for _, pt in ipairs(elements) do
      local trans_pt_list = insert_implicit_space_rule(stack[#stack], pt)
      if trans_pt_list == nil then
         -- Append to end of stack
         stack[#stack + 1] = pt
      elseif trans_pt_list[1] == nil then
         -- Remove the first element from trans_pt_list
         table.remove(trans_pt_list, 1)
         -- Extend stack with trans_pt_list
         for _, item in ipairs(trans_pt_list) do
            stack[#stack + 1] = item
         end
      else
         -- Remove last element from stack
         table.remove(stack)
         -- Extend stack with trans_pt_list
         for _, item in ipairs(trans_pt_list) do
            stack[#stack + 1] = item
         end
      end
   end

   return stack
end

local function index_tokens(parsed_tokens, bi)
   for ti = #parsed_tokens, 1, -1 do
      if parsed_tokens[ti].i <= bi then
         return ti, parsed_tokens[ti].i, parsed_tokens[ti].j
      end
   end
   error("token index of byte index " .. bi .. " not found in parsed tokens")
end

local function index_last_start_of_word(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for ti = #parsed_tokens, 1, -1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].i
      end
   end
   return nil
end

local function index_prev_start_of_word(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if ci == parsed_tokens[ti].i then
      ti = ti - 1
   end
   while ti >= 1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].i
      end
      ti = ti - 1
   end
   return nil
end

local function index_last_start_of_WORD(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   local last_valid_i = nil
   for ti = #parsed_tokens, 1, -1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         last_valid_i = parsed_tokens[ti].i
      elseif last_valid_i ~= nil then
         break
      end
   end
   return last_valid_i
end

local function index_prev_start_of_WORD(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if ci == parsed_tokens[ti].i then
      ti = ti - 1
   end
   local last_valid_i = nil
   while ti >= 1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         last_valid_i = parsed_tokens[ti].i
      elseif last_valid_i ~= nil then
         break
      end
      ti = ti - 1
   end
   return last_valid_i
end

local function index_last_end_of_word(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for ti = #parsed_tokens, 1, -1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].j
      end
   end
   return nil
end

local function index_prev_end_of_word(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci) - 1
   while ti >= 1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].j
      end
      ti = ti - 1
   end
   return nil
end

local function index_last_end_of_WORD(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for ti = #parsed_tokens, 1, -1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].j
      end
   end
   return nil
end

local function index_prev_end_of_WORD(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if parsed_tokens[ti].t == TokenType.space then
      ti = ti - 1
   else
      while ti >= 1 and parsed_tokens[ti].t ~= TokenType.space do
         ti = ti - 1
      end
   end
   while ti >= 1 do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].j
      end
      ti = ti - 1
   end
   return nil
end

local function index_first_start_of_word(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for i = 1, #parsed_tokens do
      if parsed_tokens[i].t ~= TokenType.space then
         return parsed_tokens[i].i
      end
   end
   return nil
end

local function index_next_start_of_word(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci) + 1
   while ti <= #parsed_tokens do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].i
      end
      ti = ti + 1
   end
   return nil
end

local function index_first_start_of_WORD(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for i = 1, #parsed_tokens do
      if parsed_tokens[i].t ~= TokenType.space then
         return parsed_tokens[i].i
      end
   end
   return nil
end

local function index_next_start_of_WORD(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if parsed_tokens[ti].t == TokenType.space then
      ti = ti + 1
   else
      while ti <= #parsed_tokens and parsed_tokens[ti].t ~= TokenType.space do
         ti = ti + 1
      end
   end
   while ti <= #parsed_tokens do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].i
      end
      ti = ti + 1
   end
   return nil
end

local function index_first_end_of_word(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   for _, tok in ipairs(parsed_tokens) do
      if tok.t ~= TokenType.space then
         return tok.j
      end
   end
   return nil
end

local function index_next_end_of_word(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if ci == parsed_tokens[ti].j then
      ti = ti + 1
   end
   while ti <= #parsed_tokens do
      if parsed_tokens[ti].t ~= TokenType.space then
         return parsed_tokens[ti].j
      end
      ti = ti + 1
   end
   return nil
end

local function index_first_end_of_WORD(parsed_tokens)
   if #parsed_tokens == 0 then
      return 0
   end
   local last_valid_j = nil
   for _, tok in ipairs(parsed_tokens) do
      if tok.t ~= TokenType.space then
         last_valid_j = tok.j
      elseif last_valid_j ~= nil then
         break
      end
   end
   return last_valid_j
end

local function index_next_end_of_WORD(parsed_tokens, ci)
   if #parsed_tokens == 0 then
      return nil
   end
   local ti = index_tokens(parsed_tokens, ci)
   if ci == parsed_tokens[ti].j then
      ti = ti + 1
   end
   local last_valid_j = nil
   while ti <= #parsed_tokens do
      if parsed_tokens[ti].t ~= TokenType.space then
         last_valid_j = parsed_tokens[ti].j
      elseif last_valid_j ~= nil then
         break
      end
      ti = ti + 1
   end
   return last_valid_j
end

-- determine the sentinel row and row step values based on the direction of movement
local function navigate(primary_index_func, secondary_index_func, backward, buffer, cursor_pos)
   local sentinel_row, row_step, pt
   if backward == true then
      sentinel_row = 1
      row_step = -1
   else
      sentinel_row = #buffer
      row_step = 1
   end
   -- unwrap the row and col from the cursor position
   local row, col = cursor_pos[1], cursor_pos[2]
   if row == sentinel_row then
      pt = parse_tokens(jieba.lcut(buffer[row], false))
      pt = stack_merge(pt)
      col = primary_index_func(pt, col)

      if col == nil then
         if backward == true then
            if #pt ~= 0 then
               col = pt[1].i
            else
               col = 0
            end
         else
            if #pt ~= 0 then
               col = pt[#pt].j
            else
               col = 0
            end
         end
      end
      -- return a table representing cursor position
      return { row, col }
   end
   -- similar steps for when row is not the sentinel_row
   pt = parse_tokens(jieba.lcut(buffer[row], false))
   pt = stack_merge(pt)
   col = primary_index_func(pt, col)
   if col ~= nil then
      return { row, col }
   end
   row = row + row_step
   while row ~= sentinel_row do
      pt = parse_tokens(jieba.lcut(buffer[row], false))
      pt = stack_merge(pt)
      col = secondary_index_func(pt)
      if col ~= nil then
         return { row, col }
      end
      row = row + row_step
   end
   pt = parse_tokens(jieba.lcut(buffer[row], false))
   pt = stack_merge(pt)
   col = secondary_index_func(pt)
   if col == nil then
      if backward == true then
         if #pt ~= 0 then
            col = pt[1].i
         else
            col = 0
         end
      else
         if #pt ~= 0 then
            col = pt[#pt].j
         else
            col = 0
         end
      end
   end
   return { row, col }
end

Lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)

local update_lines = function()
   Lines = vim.api.nvim_buf_get_lines(0, 0, -1, true)
end

vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "TextChangedI", "BufEnter" }, { callback = update_lines })

M.b = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_prev_start_of_word, index_last_start_of_word, true, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.B = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_prev_start_of_WORD, index_last_start_of_WORD, true, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.w = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_next_start_of_word, index_first_start_of_word, false, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
   return pos
end

M.W = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_next_start_of_WORD, index_first_start_of_WORD, false, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.e = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_next_end_of_word, index_first_end_of_word, false, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.E = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_next_end_of_WORD, index_first_end_of_WORD, false, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.ge = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_prev_end_of_word, index_last_end_of_word, true, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.gE = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local pos = navigate(index_prev_end_of_WORD, index_last_end_of_WORD, true, Lines, cursor_pos)
   vim.api.nvim_win_set_cursor(0, pos)
end

M.change_w = function()
   M.delete_w()
   vim.cmd "startinsert"
end

M.delete_w_callback = function()
   M.select_w()
   vim.cmd "normal d"
   update_lines()
end

M.delete_w = function()
   M.delete_w_callback()
   vim.o.operatorfunc = "v:lua.require'jieba_nvim'.delete_w_callback()"
   return vim.cmd "normal! g@l"
end

M.select_w = function()
   local cursor_pos = vim.api.nvim_win_get_cursor(0)
   local current_line = Lines[cursor_pos[1]]
   local line = parse_tokens(jieba.lcut(current_line, false))
   print(line)
   line = stack_merge(line)
   local _, start, row = index_tokens(line, cursor_pos[2])
   vim.api.nvim_cmd({ cmd = "normal", bang = true, args = { "v" } }, {})
   vim.api.nvim_win_set_cursor(0, { cursor_pos[1], start })
   vim.cmd "normal! o"
   vim.api.nvim_win_set_cursor(0, { cursor_pos[1], row })
end

-- local function high(line, start, stop)
-- 	local bufnr = vim.api.nvim_get_current_buf()
-- 	print(bufnr)
-- 	-- Define the highlight group and attributes
-- 	local hl_group = "MyHighlightGroup"
-- 	local hl_color = "#ff0000" -- 这里使用的是红色（#ff0000）
-- 	-- Define the start and end positions
-- 	vim.cmd("highlight " .. hl_group .. " guifg=" .. hl_color)
-- 	-- Add the highlight to the buffer
-- 	vim.api.nvim_buf_add_highlight(bufnr, -1, hl_group, line, start, stop)
-- end

-- TODO: 高亮当前光标下的词
-- local function hightlight_under_curosr()
-- 	local line = parse_tokens(jieba.lcut(vim.api.nvim_get_current_line(), false, true))
-- 	line = stack_merge(line)
-- 	local cursor_pos = vim.api.nvim_win_get_cursor(0)
-- 	local _, start, row = index_tokens(line, cursor_pos[2] + 1)
--   high(cursor_pos[1] - 1, start, row)
-- end
--
-- vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, { callback = hightlight_under_curosr })
--

return M
