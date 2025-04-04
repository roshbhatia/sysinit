-- Disable compatibility with old-time vi
vim.cmd('set nocompatible')

-- Remove viminfo warning
vim.opt.viminfo:remove({'!'})

-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set timeout for keymaps to make which-key more responsive
vim.o.timeout = true
vim.o.timeoutlen = 300

-- Disable netrw
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Line numbers
vim.opt.nu = true

-- Initialize lazy.nvim (package manager)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
    local lazyrepo = "https://github.com/folke/lazy.nvim.git"
    local out = vim.fn.system({"git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath})
    if vim.v.shell_error ~= 0 then
        vim.api.nvim_echo({{"Failed to clone lazy.nvim:\n", "ErrorMsg"}, {out, "WarningMsg"},
                         {"\nPress any key to exit..."}}, true, {})
        vim.fn.getchar()
        os.exit(1)
    end
end

vim.opt.rtp:prepend(lazypath)

-- Setup window navigation
vim.api.nvim_set_keymap('n', '<C-h>', '<C-w>h', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-j>', '<C-w>j', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-k>', '<C-w>k', { noremap = true, silent = true })
vim.api.nvim_set_keymap('n', '<C-l>', '<C-w>l', { noremap = true, silent = true })

-- We use pure nix for package management, so lazy.nvim is only used for
-- configuration organization, not for installing packages
require("lazy").setup({
    spec = {
        {"williamboman/mason.nvim"},
        {"williamboman/mason-lspconfig.nvim"},  
        {"neovim/nvim-lspconfig"},
        
        {
            'nvim-telescope/telescope.nvim',
            tag = '0.1.8',
            dependencies = {'nvim-lua/plenary.nvim'}
        },
        
        {
            "nvim-treesitter/nvim-treesitter",
            build = ":TSUpdate"
        },
        
        {
            'projekt0n/github-nvim-theme',
            lazy = false,
            priority = 1000,
            config = function()
                require('github-theme').setup({})
                vim.cmd('colorscheme github_dark')
            end
        },
        
        {
            "folke/tokyonight.nvim",
            lazy = false,
            priority = 1000,
            config = function()
                require("tokyonight").setup({
                    style = "night",
                    transparent = false,
                    terminal_colors = true,
                    styles = {
                        comments = { italic = true },
                        keywords = { italic = true },
                        functions = {},
                        variables = {}
                    }
                })
                vim.cmd("colorscheme tokyonight")
            end
        },
        
        {
            "nvim-tree/nvim-tree.lua",
            dependencies = {"nvim-tree/nvim-web-devicons"}
        },
        
        {
            "mhinz/vim-startify"
        },
        
        -- Setup which-key for the popup key binding display
        {
            "folke/which-key.nvim",
            event = "VeryLazy",
            config = function()
                local which_key = require("which-key")
                which_key.setup({
                    plugins = {
                        marks = true,
                        registers = true,
                        spelling = { enabled = false },
                        presets = {
                            operators = true,
                            motions = true,
                            text_objects = true,
                            windows = true,
                            nav = true,
                            z = true,
                            g = true,
                        },
                    },
                    window = {
                        border = "single",
                        position = "bottom",
                        margin = { 1, 0, 1, 0 },
                        padding = { 2, 2, 2, 2 },
                        winblend = 0,
                    },
                    layout = {
                        height = { min = 4, max = 25 },
                        width = { min = 20, max = 50 },
                        spacing = 3,
                        align = "left",
                    },
                    ignore_missing = false,
                    hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "^:", "^ ", "^call ", "^lua " },
                    show_help = true,
                    triggers = "auto",
                    triggers_blacklist = {
                        i = { "j", "k" },
                        v = { "j", "k" },
                    },
                })
                
                -- Register key group labels
                which_key.register({
                    ['<leader>'] = {
                        f = { name = '+find' },
                        b = { name = '+buffer' },
                        w = { name = '+workspace' },
                        c = { name = '+code/copilot' },
                        g = { name = '+git' },
                        h = { name = '+hunks' },
                        l = { name = '+lsp' },
                        s = { name = '+session' },
                        t = { name = '+toggle' },
                        x = { name = '+trouble/diagnostics' },
                        p = { name = '+project/file' },
                        n = { name = '+newline' },
                    },
                })
            end,
        },
    },
    checker = {
        enabled = true
    }
})

-- Setup LSP
require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "pyright", "clangd", "awk_ls", "bashls", "dockerls", 
        "eslint", "gopls", "jsonls", "marksman", "pylsp", 
        "tflint", "yamlls", "lua_ls"
    }
})

-- Configure LSP servers
local lspconfig = require("lspconfig")
lspconfig.pyright.setup{}
lspconfig.gopls.setup{}
lspconfig.lua_ls.setup{}

-- Setup NvimTree
require("nvim-tree").setup({
    sort = {
        sorter = "case_sensitive"
    },
    view = {
        width = 30
    },
    renderer = {
        group_empty = true
    },
    update_focused_file = {
        enable = true
    }
})

-- Setup web devicons
require'nvim-web-devicons'.setup {
    override = {
        zsh = {
            icon = "",
            color = "#428850",
            cterm_color = "65",
            name = "Zsh"
        }
    },
    color_icons = true,
    default = true,
    strict = true,
    override_by_filename = {
        [".gitignore"] = {
            icon = "",
            color = "#f1502f",
            name = "Gitignore"
        }
    },
    override_by_extension = {
        ["log"] = {
            icon = "",
            color = "#81e043",
            name = "Log"
        }
    },
    override_by_operating_system = {
        ["apple"] = {
            icon = "",
            color = "#A2AAAD", 
            cterm_color = "248",
            name = "Apple"
        }
    }
}

-- Telescope keybindings
local builtin = require('telescope.builtin')
vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

-- Set colorscheme with vibrant colors
vim.cmd [[colorscheme tokyonight-night]]

-- Load Startify config
require('config.startify')

-- Create IBLDisable and IBLEnable commands that are guaranteed to exist
vim.api.nvim_create_user_command('IBLDisable', function()
  pcall(function()
    local ok, ibl = pcall(require, 'ibl')
    if ok then
      ibl.setup_buffer(0, { enabled = false })
    end
  end)
end, {})

vim.api.nvim_create_user_command('IBLEnable', function()
  pcall(function()
    local ok, ibl = pcall(require, 'ibl')
    if ok then
      ibl.setup_buffer(0, { enabled = true })
    end
  end)
end, {})

-- Create command aliases for backward compatibility
vim.cmd([[
  command! -bar IndentBlanklineDisable IBLDisable
  command! -bar IndentBlanklineEnable IBLEnable
]])

-- Fix for Startify and indent-blankline
vim.api.nvim_create_autocmd("FileType", {
  pattern = "startify",
  callback = function()
    -- Disable indent-blankline directly at the buffer level
    pcall(function() 
      vim.cmd('IBLDisable')
    end)
  end
})

-- Initialize mini modules
pcall(function()
  -- Mini.animate for smooth animations
  require('mini.animate').setup({
    cursor = {
      enable = true,
      timing = function(_, n) return 150 / n end,
      path = require('mini.animate').gen_path.line(),
    },
    scroll = {
      enable = true,
      timing = function(_, n) return 200 / n end,
      subscroll = require('mini.animate').gen_subscroll.cubic({ easing = 'in-out' }),
    },
    resize = {
      enable = true,
      timing = function(_, n) return 100 / n end,
    },
    open = {
      enable = true,
      timing = function(_, n) return 250 / n end,
    },
    close = {
      enable = true,
      timing = function(_, n) return 250 / n end,
    },
  })
  
  -- Other mini modules
  require('mini.pairs').setup() -- Auto pairs (better than nvim-autopairs)
  require('mini.surround').setup() -- Surround text objects
  require('mini.comment').setup() -- Comment toggling
  require('mini.indentscope').setup({
    symbol = "│",
    options = { try_as_border = true }
  })
end)

-- Setup NvimTree toggle keybinding
vim.keymap.set('n', '<F2>', ':NvimTreeToggle<CR>', {noremap = true, silent = true})

-- Initialize heirline
pcall(function()
  local heirline_config = require('config.heirline_setup')
  require('heirline').setup({
    statusline = heirline_config.statusline,
    tabline = heirline_config.tabline,
    opts = heirline_config.opts,
  })
end)

-- DAP (Debug Adapter Protocol) disabled for now

-- Initialize none-ls for formatting and linting
pcall(function()
  local null_ls = require("null-ls")
  
  null_ls.setup({
    sources = {
      -- Formatters
      null_ls.builtins.formatting.stylua,
      null_ls.builtins.formatting.prettier,
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.gofmt,
      null_ls.builtins.formatting.rustfmt,
      
      -- Linters
      null_ls.builtins.diagnostics.eslint,
      null_ls.builtins.diagnostics.pylint,
    }
  })
end)