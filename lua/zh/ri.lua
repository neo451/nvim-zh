local yaml = require "yaml"

-- local shared_data_dir = "/usr/share/rime-data/"
local shared_data_dir = "/home/n451/Plugins/nvim-zh/data/"

local function parse_yaml(name)
   local file = vim.fn.readfile(shared_data_dir .. name)
   local str = table.concat(file, "\n")
   return yaml.load(str)
end

local function parse_dict(name)
   local res = {}
   local f = io.open(shared_data_dir .. name)
   if f then
      for line in f:lines() do
         local chr, pin = line:match "(%S+)%s+(%w+)"
         if chr then
            res[chr] = pin
         end
      end
   end
   return res
end

print(vim.inspect(parse_dict "luna_pinyin.dict.yaml"))
