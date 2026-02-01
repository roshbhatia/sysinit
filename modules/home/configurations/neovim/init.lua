vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Filter out noisy/unhelpful error messages
local original_notify = vim.notify
---@diagnostic disable-next-line: duplicate-set-field
vim.notify = function(msg, level, opts)
  if type(msg) == "string" then
    -- Filter Neovim nightly extui window race condition errors
    if msg:match("Invalid window id:") and msg:match("_extui/cmdline%.lua") then
      return
    end
    -- Filter nil_ls flake input evaluation errors (expected for some inputs)
    if msg:match("Flake input .* cannot be evaluated") then
      return
    end
    -- Filter Neovim nightly LSP diagnostic handler errors (malformed diagnostic data)
    if msg:match("attempt to get length of local 'diagnostics'") then
      return
    end
  end
  return original_notify(msg, level, opts)
end

require("vim._extui").enable({})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
---@diagnostic disable-next-line: undefined-field
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end

vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    {
      import = "sysinit.plugins",
    },
  },
  install = {
    colorscheme = { "default" },
  },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
  ui = {
    border = "rounded",
  },
})

-- Fallback theme when not Nix-managed
require("sysinit.core.theme-fallback").setup()

-- Apply transparency settings
require("sysinit.core.transparency").apply()
