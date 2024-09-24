-- TODO: cmp-text, to fill in jieba-words based on the frist letter ...
-- TODO: maintain matching brackets

local lpeg = vim.lpeg
local M = {}
local ut = require "jieba.utils"
local sub = ut.sub
-- E011	中英文之间空格数量多于 1 个
-- E012	中文和数字之间空格数量多于 1 个
-- E014	英文和数字之间空格数量多于 1 个
-- E016	连续的空行数量大于 2 行

---@param s string
---@return boolean
local function has_rep(s)
   for j = 1, #s, 2 do
      if sub(s, j, j) == sub(s, j + 1, j + 1) then
         return true
         -- err(i, "E015")
      end
   end
   return false
end

function M.lint(str, row)
   local state = M.parse(str)
   local fst, scd, trd
   local errs = {}
   local function err(i, errname)
      errs[#errs + 1] = {
         row = row or 1,
         col = state.start[i],
         end_col = state.start[i + 1] + #state.content[i] + 1,
         err = errname,
      }
   end

   for i = 1, #state.type, 2 do
      fst, scd, trd = state.type[i], state.type[i + 1], state.type[i + 2]
      -- E001	中文字符后存在英文标点
      if fst == "hans" and scd == "halfwidth" then
         err(i, "E001")
      -- E002	中英文之间没有空格
      elseif (fst == "hans" and scd == "western") or (scd == "hans" and fst == "western") then
         err(i, "E002")
      -- E003	中文与数字之间没有空格
      elseif (fst == "hans" and scd == "number") or (scd == "hans" and fst == "number") then
         err(i, "E003")
      -- E004	中文标点两侧存在空格
      elseif (fst == "fullwidth" and scd == "space") or (scd == "fullwidth" and fst == "space") then
         err(i, "E004")
         -- TODO: E006	数字和单位之间存在空格
         -- elseif (fst == "fullwidth" and scd == "space") or (scd == "fullwidth" and fst == "space") then
         -- 	err(i, "E006")
         -- E008	汉字之间存在空格
         -- E009	中文标点重复
      elseif fst == "fullwidth" or scd == "fullwidth" then
         if fst == "fullwidth" then
            local s = state.content[i]
            if has_rep(s) then
               err(i, "E009")
            end
         elseif scd == "fullwidth" then
            local s = state.content[i + 1]
            if has_rep(s) then
               err(i, "E009")
            end
         end
      elseif fst == "hans" and scd == "space" and trd == "hans" then
         err(i, "E008")
         -- E013	英文和数字之间没有空格
      elseif (fst == "western" and scd == "number") or (scd == "western" and fst == "number") then
         err(i, "E013")
         -- E015	英文标点重复
      elseif fst == "halfwidth" or scd == "halfwidth" then
         if fst == "halfwidth" then
            local s = state.content[i]
            if has_rep(s) then
               err(i, "E015")
            end
         elseif scd == "halfwidth" then
            local s = state.content[i + 1]
            if has_rep(s) then
               err(i, "E015")
            end
         end
         -- E017	数字之间存在空格
      elseif fst == "number" and scd == "space" and trd == "number" then
         err(i, "E017")
      end
      -- E007	数字使用了全角字符
      -- E010	英文标点符号两侧的空格数量不对
      -- E005	行尾含有空格
   end
   return errs
end

local map = {
   E001 = "中文字符后存在英文标点",
   E002 = "中英文之间没有空格",
   E003 = "中文与数字之间没有空格",
   E004 = "中文标点两侧存在空格",
   E005 = "行尾含有空格",
   E006 = "数字和单位之间存在空格",
   E007 = "数字使用了全角字符",
   E008 = "汉字之间存在空格",
   E009 = "中文标点重复",
   E010 = "英文标点符号两侧的空格数量不对",
   E011 = "中英文之间空格数量多于 1 个",
   E012 = "中文和数字之间空格数量多于 1 个",
   E013 = "英文和数字之间没有空格",
   E014 = "英文和数字之间空格数量多于 1 个",
   E015 = "英文标点重复",
   E016 = "连续的空行数量大于 2 行",
   E017 = "数字之间存在空格",
}

local ok, null_ls = pcall(require, "null_ls")

if ok then
   null_ls {
      method = null_ls.methods.DIAGNOSTICS,
      filetypes = { "markdown", "text", "norg" },
      generator = {
         fn = function(params)
            local diagnostics = {}
            for i, line in ipairs(params.content) do
               -- print(i, line)
               if line ~= "" then
                  local parsed = M.lint(line, i)
                  for _, err in ipairs(parsed) do
                     diagnostics[#diagnostics + 1] = {
                        row = i,
                        -- col = 1,
                        -- end_col = 2,
                        source = "zh-lint",
                        message = map[err.err],
                        severity = vim.diagnostic.severity.WARN,
                     }
                  end
               end
            end
            return diagnostics
         end,
      },
   }
end

return M
