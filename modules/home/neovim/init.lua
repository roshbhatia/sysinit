-- Disable compatibility with old-time vi
vim.cmd('set nocompatible')

-- Remove viminfo warning
vim.opt.viminfo:remove({'!'})

-- Set leader key before anything else
vim.g.mapleader = " "
vim.g.maplocalleader = " "

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

-- Plugin setup
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
        }
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