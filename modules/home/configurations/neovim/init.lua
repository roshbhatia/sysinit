vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.o.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"

-- Filter out noisy/unhelpful error messages
local original_notify = vim.notify
vim.notify = function(msg, level, opts)
  if type(msg) == "string" then
    if msg:match("Invalid window id:") and msg:match("_extui/cmdline%.lua") then
      return
    end
    if msg:match("Flake input .* cannot be evaluated") then
      return
    end
    if msg:match("attempt to get length of local 'diagnostics'") then
      return
    end
  end
  return original_notify(msg, level, opts)
end

require("vim._extui").enable({})

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
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
    "RRethy/base16-nvim",
    {
      import = "sysinit.plugins",
    },
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
