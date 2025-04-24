-- Mark this as a VSCode instance
vim.g.vscode = true

local function setup_lazy()
  local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
  if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
      "git", "clone", "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", lazypath,
    })
  end
  vim.opt.rtp:prepend(lazypath)

  -- Add lua directory to runtime path
  local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
  local lua_dir = init_dir .. "/lua"
  vim.opt.rtp:prepend(lua_dir)
end

-- Basic leader setup
local function setup_leader()
  vim.g.mapleader = " "
  vim.g.maplocalleader = " "
  -- Prevent space from moving cursor in normal/visual mode
  vim.keymap.set({ "n", "v" }, "<Space>", "<Nop>", { noremap = true, silent = true })
end

-- Common Neovim settings
local function setup_common_settings()
  -- Search settings
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Indentation settings
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  -- Window behavior
  vim.opt.splitbelow = true
  vim.opt.splitright = true

  -- Performance and usability
  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"
end

-- VSCode integration specific settings
local function setup_vscode_integration()
  if not vim.g.vscode then return end
  -- Suppress VimEnter autocommands to avoid premature remote plugin bootstrap errors
  vim.cmd("set eventignore+=VimEnter")
  vim.notify("VSCode Neovim integration detected", vim.log.levels.INFO)
end

-- Initialize module loader and setup plugins
local function setup_plugins()
  local ok, module_loader = pcall(require, "core.vsc_module_loader")
  if not ok then
    vim.notify("Failed to load core.vsc_module_loader: " .. tostring(module_loader), vim.log.levels.ERROR)
    return
  end

  -- Define module system
  local module_system = {
    vscode = {
      "vsc-which-key",
      "vsc-commands",
      "vsc-keybindings",
      "vsc-jumpy"
    }
  }

  -- Collect plugin specs
  local function collect_plugin_specs()
    local specs = module_loader.get_plugin_specs(module_system)
    return specs
  end

  local lazy_ok, lazy = pcall(require, "lazy")
  if not lazy_ok then
    vim.notify("Failed to load lazy.nvim: " .. tostring(lazy), vim.log.levels.ERROR)
    return
  end

  lazy.setup(collect_plugin_specs())
  module_loader.setup_modules(module_system)
end

-- Safeguard for ephemeral buffers
local function is_valid_buffer(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted")
end

-- Main initialization function
local function init()
  -- If running under VSCode, override notifications to use VSCode UI
  if vim.g.vscode then
    local ok, vscode_mod = pcall(require, "vscode")
    if ok and vscode_mod.notify then
      vim.notify = vscode_mod.notify
    end
  end
  
  -- Basic initialization - works even if subsequent steps fail
  setup_lazy()
  setup_leader()
  setup_common_settings()
  setup_vscode_integration()
  
  -- Try to load plugins (may fail if modules aren't available)
  pcall(setup_plugins)
end

-- Override Neovim's buffer-related commands to check for valid buffers
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    local bufnr = vim.api.nvim_get_current_buf()
    if not is_valid_buffer(bufnr) then
      vim.notify("Ignoring ephemeral buffer: " .. tostring(bufnr), vim.log.levels.WARN)
      return
    end
  end,
})

-- Run initialization
init()