--[[---------------------------------------
             Neovim Configuration
             
  Author: Rosh Bhatia
  Repo: github.com/roshbhatia/sysinit
  
  This configuration works in:
  - Regular Neovim
  - VSCode Neovim extension
-----------------------------------------]]

-- Detect if we're running under VSCode
vim.g.vscode = (vim.fn.exists('g:vscode') == 1) or (vim.env.VSCODE_GIT_IPC_HANDLE ~= nil)

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
local lua_dir = init_dir .. "/lua"
vim.opt.rtp:prepend(lua_dir)

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

vim.opt.clipboard = "unnamedplus"

-- Set Shift+Space as command line trigger
vim.keymap.set('n', '<S-Space>', ':', { noremap = true })

-- Explicitly register space key to do nothing (prevents default space behavior)
vim.keymap.set('n', '<Space>', '<NOP>')

-- Common settings (for both regular Neovim and VSCode)
local function setup_common_settings()
  -- Search settings
  vim.opt.hlsearch = true
  vim.opt.incsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true

  -- Editing experience
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 2
  vim.opt.tabstop = 2
  vim.opt.smartindent = true
  vim.opt.wrap = false
  vim.opt.linebreak = true
  vim.opt.breakindent = true

  -- Splits and windows
  vim.opt.splitbelow = true
  vim.opt.splitright = true

  -- Performance options
  vim.opt.updatetime = 100
  vim.opt.timeoutlen = 300

  -- Scrolling
  vim.opt.scrolloff = 8
  vim.opt.sidescrolloff = 8

  -- Other options
  vim.opt.mouse = "a"
  vim.opt.clipboard = "unnamedplus"  -- Use system clipboard
end

-- Regular Neovim-only settings
local function setup_neovim_settings()
  -- UI settings
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.opt.signcolumn = "yes"
  vim.opt.termguicolors = true
  vim.opt.showmode = false  -- Hide mode since we use lualine
  vim.opt.lazyredraw = true
  
  -- Folding
  vim.opt.foldmethod = "expr"
  vim.opt.foldexpr = "nvim_treesitter#foldexpr()"
  vim.opt.foldenable = false
  vim.opt.foldlevel = 99

  -- UI improvements
  vim.opt.pumheight = 10        -- Limit completion menu height
  vim.opt.cmdheight = 1         -- More space for displaying messages
  vim.opt.hidden = true         -- Enable background buffers
  vim.opt.showtabline = 2       -- Always show tabline
  vim.opt.shortmess:append("c") -- Don't show completion messages
  vim.opt.completeopt = { "menuone", "noselect" }
end

-- VSCode-specific settings and keybindings
local function setup_vscode_settings()
  -- Basic navigation - make sure hjkl works properly with wrapped lines
  vim.keymap.set('n', 'j', 'gj', { silent = true })
  vim.keymap.set('n', 'k', 'gk', { silent = true })
  
  -- VSCode command wrapper function
  local function vscode_cmd(command)
    return function() 
      if vim.fn.exists('*VSCodeNotify') == 1 then
        vim.fn.VSCodeNotify(command)
      elseif vim.fn.exists('*vscode.call') == 1 then
        vim.call('vscode.call', command)
      end
    end
  end
  
  -- Navigation mappings - match our standard Neovim navigation
  vim.keymap.set('n', 'gd', vscode_cmd('editor.action.revealDefinition'), { silent = true })
  vim.keymap.set('n', 'gr', vscode_cmd('editor.action.goToReferences'), { silent = true })
  vim.keymap.set('n', 'gi', vscode_cmd('editor.action.goToImplementation'), { silent = true })
  vim.keymap.set('n', 'K', vscode_cmd('editor.action.showHover'), { silent = true })
  vim.keymap.set('n', '<C-k>', vscode_cmd('editor.action.showHover'), { silent = true })
  
  -- Leader mappings that match our core keybindings
  vim.keymap.set('n', '<leader>ff', vscode_cmd('workbench.action.quickOpen'), { silent = true })
  vim.keymap.set('n', '<leader>fg', vscode_cmd('workbench.action.findInFiles'), { silent = true })
  vim.keymap.set('n', '<leader>e', vscode_cmd('workbench.view.explorer'), { silent = true })
  
  -- Code actions to match our standard bindings
  vim.keymap.set('n', '<leader>ca', vscode_cmd('editor.action.quickFix'), { silent = true })
  vim.keymap.set('n', '<leader>rn', vscode_cmd('editor.action.rename'), { silent = true })
  vim.keymap.set('n', '<leader>cf', vscode_cmd('editor.action.formatDocument'), { silent = true })
  
  -- Comment toggling
  vim.keymap.set('n', 'gcc', vscode_cmd('editor.action.commentLine'), { silent = true })
  vim.keymap.set('v', 'gc', vscode_cmd('editor.action.commentLine'), { silent = true })
  
  -- Terminal toggle - match our main config's mapping
  vim.keymap.set('n', '<leader>tt', vscode_cmd('workbench.action.terminal.toggleTerminal'), { silent = true })
  
  -- Git operations
  vim.keymap.set('n', '<leader>gs', vscode_cmd('workbench.view.scm'), { silent = true })
  vim.keymap.set('n', '<leader>gb', vscode_cmd('gitlens.toggleFileBlame'), { silent = true })
  
  -- Window navigation that matches our standard navigation
  vim.keymap.set('n', '<C-h>', vscode_cmd('workbench.action.navigateLeft'), { silent = true })
  vim.keymap.set('n', '<C-j>', vscode_cmd('workbench.action.navigateDown'), { silent = true })
  vim.keymap.set('n', '<C-k>', vscode_cmd('workbench.action.navigateUp'), { silent = true })
  vim.keymap.set('n', '<C-l>', vscode_cmd('workbench.action.navigateRight'), { silent = true })
  
  -- Session management via workspaces
  vim.keymap.set('n', '<leader>ss', vscode_cmd('workbench.action.files.saveWorkspaceAs'), { silent = true })
  vim.keymap.set('n', '<leader>sl', vscode_cmd('workbench.action.openRecent'), { silent = true })
  
  -- Configure neoscroll for VSCode if available
  local ok, neoscroll = pcall(require, "neoscroll")
  if ok then
    -- Use more VSCode-friendly settings
    neoscroll.setup({
      hide_cursor = false,
      performance_mode = false,
      easing = 'linear',
      mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
    })
  end
  
  -- Configure autosession for VSCode
  local session_ok, auto_session = pcall(require, "auto-session")
  if session_ok then
    auto_session.setup({
      auto_save_enabled = false,
      auto_restore_enabled = false,
    })
  end
end

-- Apply settings based on environment
setup_common_settings()
if vim.g.vscode then
  setup_vscode_settings()
else
  setup_neovim_settings()
end

-- Define different module sets for regular Neovim and VSCode
local module_system

-- Regular Neovim modules
if not vim.g.vscode then
  module_system = {
    -- Core editor functionality
    editor = {
      "which-key",
      "telescope",
      "oil",
      "wilder",
    },
    -- UI-related modules
    ui = {
      "carbonfox",
      "devicons",
      "lualine",
      "nvimtree",
      "wezterm",
    },
    -- Tool modules
    tools = {
      "autosession",
      "comment",
      "hop",
      "neoscroll",
      "treesitter",
    }
  }
else
  -- VSCode-Neovim modules (minimal set)
  module_system = {
    -- Core functionality
    editor = {
      "which-key",
    },
    -- No UI modules needed
    ui = {},
    -- Minimal tool modules
    tools = {
      "autosession",
      "comment",
      "hop",
      "neoscroll",
    }
  }
end

-- Collect plugin specs from all modules
local function collect_plugin_specs()
  local specs = {}
  
  -- Process modules in specific order
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(module_system[category]) do
      local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
      if ok and module.plugins then
        vim.list_extend(specs, module.plugins)
      end
    end
  end
  
  -- Add common plugins like LSP and completion
  if not vim.g.vscode then
    -- Regular Neovim plugins (LSP, completion, etc.)
    table.insert(specs, {
      "neovim/nvim-lspconfig",
      dependencies = {
        "williamboman/mason.nvim",
        "williamboman/mason-lspconfig.nvim",
        "hrsh7th/nvim-cmp",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-cmdline",
        "L3MON4D3/LuaSnip",
        "saadparwaiz1/cmp_luasnip",
      },
      config = function()
        -- Configure LSP and autocompletion
        require("mason").setup()
        require("mason-lspconfig").setup({
          ensure_installed = { "lua_ls", "rust_analyzer", "pyright", "ts_ls" },
          automatic_installation = true,
        })
        
        -- Set up nvim-cmp
        local cmp = require("cmp")
        local luasnip = require("luasnip")
        
        cmp.setup({
          snippet = {
            expand = function(args)
              luasnip.lsp_expand(args.body)
            end,
          },
          mapping = cmp.mapping.preset.insert({
            ["<C-b>"] = cmp.mapping.scroll_docs(-4),
            ["<C-f>"] = cmp.mapping.scroll_docs(4),
            ["<C-Space>"] = cmp.mapping.complete(),
            ["<C-e>"] = cmp.mapping.abort(),
            ["<CR>"] = cmp.mapping.confirm({ select = true }),
            ["<Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_next_item()
              elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
              else
                fallback()
              end
            end, { "i", "s" }),
            ["<S-Tab>"] = cmp.mapping(function(fallback)
              if cmp.visible() then
                cmp.select_prev_item()
              elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
              else
                fallback()
              end
            end, { "i", "s" }),
          }),
          sources = cmp.config.sources({
            { name = "nvim_lsp" },
            { name = "luasnip" },
          }, {
            { name = "buffer" },
            { name = "path" },
          }),
        })
        
        -- Use buffer source for `/` and `?`
        cmp.setup.cmdline({ '/', '?' }, {
          mapping = cmp.mapping.preset.cmdline(),
          sources = {
            { name = 'buffer' }
          }
        })
        
        -- Use cmdline & path source for ':'
        cmp.setup.cmdline(':', {
          mapping = cmp.mapping.preset.cmdline(),
          sources = cmp.config.sources({
            { name = 'path' }
          }, {
            { name = 'cmdline' }
          })
        })
        
        -- Set up LSP servers
        local capabilities = require("cmp_nvim_lsp").default_capabilities()
        
        local lspconfig = require("lspconfig")
        local servers = { "lua_ls", "rust_analyzer", "pyright", "ts_ls" }
        
        for _, lsp in ipairs(servers) do
          lspconfig[lsp].setup({
            capabilities = capabilities,
          })
        end
        
        -- Global LSP mappings
        vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, { desc = "Go to declaration" })
        vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { desc = "Go to definition" })
        vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = "Show hover information" })
        vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { desc = "Go to implementation" })
        vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, { desc = "Show signature help" })
        vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, { desc = "Rename symbol" })
        vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { desc = "Code action" })
        vim.keymap.set('n', 'gr', vim.lsp.buf.references, { desc = "Find references" })
      end
    })
    
    -- Autopairs
    table.insert(specs, {
      "windwp/nvim-autopairs",
      event = "InsertEnter",
      config = function()
        require("nvim-autopairs").setup({
          check_ts = true,
          ts_config = {
            lua = {'string'},
            javascript = {'template_string'},
            java = false,
          },
        })
      end
    })
    
    -- Git integration
    table.insert(specs, {
      "lewis6991/gitsigns.nvim",
      config = function()
        require("gitsigns").setup()
      end
    })
  end
  
  return specs
end

-- Setup Lazy.nvim with collected specs
require("lazy").setup(collect_plugin_specs())
