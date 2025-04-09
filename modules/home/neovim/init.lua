-- Ensure Lua modules in 'lua/' are accessible
vim.opt.rtp:append(vim.fn.stdpath("config") .. "/lua")
vim.opt.rtp:append(vim.fn.stdpath("config") .. "/modules/home/neovim/lua")

-- Load core modules from lua/
require('bootstrap')
-- ...add other modules like settings, plugins, keymaps, etc., as needed...
