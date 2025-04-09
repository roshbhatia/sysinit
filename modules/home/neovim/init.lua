do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

require("core.options") 
require("core.keymaps")
require("core.autocmds")

require("config.config").setup()