-- Allow dynamic runtime directory configuration
local runtime_dir = vim.env.NVIM_RUNTIME_DIR or vim.fn.expand("~/.local/share/sysinit-nvim")
vim.env.XDG_DATA_HOME = runtime_dir

local lazypath = runtime_dir .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  })
  print("Lazy.nvim installed at " .. lazypath)
end
vim.opt.rtp:prepend(lazypath)

-- Set up leader keys
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Initialize core and collect plugin specs
local core = require("core").init()

-- Initialize Lazy.nvim with collected plugin specs
require("lazy").setup(core.get_plugin_specs(), {
  install = { colorscheme = { "carbonfox" } },
  checker = { enabled = true },
})

-- Load modules after plugins are ready
vim.api.nvim_create_autocmd("User", {
  pattern = "LazyDone",
  callback = function()
    core.load_all()
  end,
})

-- Global variable to track Lazy.nvim UI state
vim.g.lazy_ui_state = 0

-- Bind Lazy.nvim to <leader>0
vim.keymap.set("n", "<leader>0", function()
  local lazy = require("lazy")
  if vim.g.lazy_ui_state == 0 then
    lazy.show() -- Show Lazy.nvim UI
    vim.g.lazy_ui_state = 1
  else
    vim.cmd("q") -- Close Lazy.nvim UI
    vim.g.lazy_ui_state = 0
  end
end, { noremap = true, silent = true, desc = "Toggle Lazy.nvim" })

print("Lazy.nvim setup complete")
