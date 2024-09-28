local jieba = require "zh.jieba"
local flypy_table = require "zh.flypy"
local M = {}

local flypy = function(str)
   if flypy_table[str] ~= nil then
      return string.sub(flypy_table[str], 1, 2) -- 暂时只有一个音
   else
      return str
   end
end

local function reverse(x)
   local rev = {}
   for i = #x, 1, -1 do
      rev[#rev + 1] = x[i]
   end
   return rev
end

local function split_char(str)
   local res = {}
   local p = "[%z\1-\127\194-\244][\128-\191]*"

   for ch in string.gmatch(str, p) do
      table.insert(res, ch)
   end
   return res
end

local parse_line = function(str, line)
   local cum_l = 1
   local parsed = {}
   local tokens = split_char(str)
   for _, tok in ipairs(tokens) do
      local i = cum_l
      local t = flypy(tok)
      cum_l = cum_l + #tok
      parsed[#parsed + 1] = { row = line, col = i, t = t }
   end
   return parsed
end

local parse = function()
   local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
   local parsed = {}
   for i, line in ipairs(lines) do
      local parsed_line = parse_line(line, i)
      for _, tok in ipairs(parsed_line) do
         parsed[#parsed + 1] = tok
      end
   end
   return parsed
end

local parse_jieba = function()
   local cum_l = 1
   local parsed = {}
   local str = vim.api.nvim_get_current_line()
   local row = vim.api.nvim_win_get_cursor(0)[1]
   local col = vim.api.nvim_win_get_cursor(0)[2]
   local tokens = jieba.lcut(str, false)
   for _, tok in ipairs(tokens) do
      local i = cum_l
      cum_l = cum_l + #tok
      if #tok >= 6 and i > col then
         parsed[#parsed + 1] = { pos = { row, i } }
      end
   end
   return parsed
end

local function get_char()
   local i = 1
   local tmp = ""
   while i < 3 do
      local a = vim.fn.getcharstr()
      tmp = tmp .. a
      i = i + 1
   end
   return tmp
end

local find_han = function()
   local str = get_char()
   local parsed = parse()
   local pos = vim.api.nvim_win_get_cursor(0)
   local found = {}
   for _, tok in ipairs(parsed) do
      if tok.t == str and tok.row == pos[1] and tok.col > pos[2] then
         found[#found + 1] = { pos = { tok.row, tok.col } }
      elseif tok.t == str and tok.row > pos[1] then
         found[#found + 1] = { pos = { tok.row, tok.col } }
      end
   end
   return found
end

local find_han_bak = function()
   local str = get_char()
   local parsed = parse()
   local pos = vim.api.nvim_win_get_cursor(0)
   local found = {}
   for _, tok in ipairs(parsed) do
      if tok.t == str and tok.row == pos[1] and tok.col < pos[2] then
         found[#found + 1] = { pos = { tok.row, tok.col } }
      elseif tok.t == str and tok.row < pos[1] then
         found[#found + 1] = { pos = { tok.row, tok.col } }
      end
   end
   return reverse(found)
end

local find_han_all = function()
   local str = get_char()
   local pos = vim.api.nvim_win_get_cursor(0)
   local parsed = parse()
   local rev = {}
   local found = {}
   for _, tok in ipairs(parsed) do
      if tok.t == str then
         if tok.row == pos[1] then
            if tok.col > pos[2] then
               found[#found + 1] = { pos = { tok.row, tok.col } }
            else
               rev[#rev + 1] = { pos = { tok.row, tok.col } }
            end
         else
            if tok.row > pos[1] then
               found[#found + 1] = { pos = { tok.row, tok.col } }
            else
               rev[#rev + 1] = { pos = { tok.row, tok.col } }
            end
         end
      end
   end
   for _, tok in ipairs(reverse(rev)) do
      found[#found + 1] = tok
   end
   return found
end

M.leap_zh = function()
   require("leap").leap {
      targets = find_han(),
   }
end

M.leap_zh_bak = function()
   require("leap").leap {
      targets = find_han_bak(),
   }
end

M.leap_zh_all = function()
   require("leap").leap {
      targets = find_han_all(),
   }
end

M.leap_jieba = function()
   require("leap").leap {
      targets = parse_jieba(),
   }
end

return M
