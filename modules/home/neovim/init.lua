-- Configure package path
do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

-- Load core options and keymaps from modules
local options_ok, _ = pcall(require, "core.options")
if not options_ok then
  -- Fallback options if the module fails to load
  vim.opt.compatible = false
  vim.opt.number = true
  vim.opt.tabstop = 2
  vim.opt.shiftwidth = 2
  vim.opt.expandtab = true
  vim.opt.smartindent = true
  vim.opt.termguicolors = true
  vim.opt.syntax = "on"
  vim.opt.backspace = "indent,eol,start"
  vim.opt.incsearch = true
  vim.opt.hlsearch = true
  vim.opt.ignorecase = true
  vim.opt.smartcase = true
  vim.opt.mouse = "a"
  vim.opt.showcmd = true
  vim.opt.ruler = true
  vim.opt.laststatus = 2
  vim.opt.title = true
  vim.opt.cursorline = true
  vim.opt.autoread = true
  vim.opt.showmode = true
  vim.opt.hidden = true
  
  print("Using fallback options (core.options not loaded)")
end

-- Set leader key
vim.g.mapleader = " "

-- Load keymaps module
local keymaps_ok, _ = pcall(require, "core.keymaps")
if not keymaps_ok then
  -- Fallback basic keymaps if the module fails
  vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>Q', ':qa!<CR>', { noremap = true, silent = true })
  
  print("Using fallback keymaps (core.keymaps not loaded)")
end

-- Load autocmds module (optional for now)
local autocmd_ok, _ = pcall(require, "core.autocmds")
if not autocmd_ok then
  print("Note: core.autocmds not loaded (this is normal for initial testing)")
end

-- PHASE 2: Add Lazy.nvim plugin manager with minimal plugins
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  print("Installing lazy.nvim...")
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

-- Key mapping to show lazy ui
vim.keymap.set('n', '<leader>l', ':Lazy<CR>', { noremap = true, silent = true, desc = "Open Lazy.nvim" })

-- PHASE 4: Add selective plugins from plugins directory
require("lazy").setup({
  -- Core plugins
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {
      -- Simple Which-Key setup
    },
  },
  
  -- Theme and transparency management
  {
    "xiyaowong/transparent.nvim",
    lazy = false,
    config = function()
      require("transparent").setup({
        groups = {
          'Normal', 'NormalNC', 'Comment', 'Constant', 'Special', 'Identifier',
          'Statement', 'PreProc', 'Type', 'Underlined', 'Todo', 'String', 'Function',
          'Conditional', 'Repeat', 'Operator', 'Structure', 'LineNr', 'NonText',
          'SignColumn', 'CursorLine', 'CursorLineNr', 'StatusLine', 'StatusLineNC',
          'EndOfBuffer',
        },
        extra_groups = {},
        exclude_groups = {},
      })
      -- Start with transparency disabled
      require("transparent").clear_prefix("BufferLine")
      vim.g.transparent_enabled = false
    end,
  },
  
  -- Theme Switcher
  {
    "zaldih/themery.nvim",
    lazy = false,
    keys = {
      { "<leader>tt", "<cmd>Themery<CR>", desc = "Switch Theme" },
    },
    config = function()
      -- Helper function to toggle transparency
      _G.toggle_transparency = function()
        vim.g.transparent_enabled = not vim.g.transparent_enabled
        if vim.g.transparent_enabled then
          require("transparent").enable()
          print("Transparency enabled")
        else
          require("transparent").disable()
          print("Transparency disabled")
        end
      end
      
      -- Create transparency toggle mapping
      vim.api.nvim_set_keymap("n", "<leader>tp", [[<cmd>lua toggle_transparency()<CR>]], { noremap = true, silent = true, desc = "Toggle transparency" })
      
      -- Setup Themery with a variety of vibrant dark themes
      require("themery").setup({
        themes = {
          -- Classic dark themes with vibrant colors
          {
            name = "Tokyo Night",
            colorscheme = "tokyonight",
            before = [[
              vim.g.tokyonight_style = "night"
              vim.g.tokyonight_italic_functions = true
            ]],
          },
          {
            name = "Tokyo Night Storm",
            colorscheme = "tokyonight-storm",
          },
          {
            name = "Catppuccin Mocha",
            colorscheme = "catppuccin-mocha",
          },
          {
            name = "Dracula",
            colorscheme = "dracula",
          },
          {
            name = "Gruvbox Dark",
            colorscheme = "gruvbox",
            before = [[vim.opt.background = "dark"]],
          },
          {
            name = "OneDark Deep",
            colorscheme = "onedark",
            before = [[
              require('onedark').setup {
                style = 'deep',
                transparent = vim.g.transparent_enabled,
                toggle_style_key = nil,
                code_style = {
                  comments = 'italic',
                  functions = 'bold',
                  strings = 'none',
                  variables = 'none'
                },
              }
              require('onedark').load()
            ]],
          },
          {
            name = "Nightfox",
            colorscheme = "nightfox",
          },
          {
            name = "Carbonfox",
            colorscheme = "carbonfox",
          },
          {
            name = "Terafox",
            colorscheme = "terafox",
          },
          {
            name = "Nordfox",
            colorscheme = "nordfox",
          },
          {
            name = "Duskfox",
            colorscheme = "duskfox",
          },
          {
            name = "Everforest Dark",
            colorscheme = "everforest",
            before = [[
              vim.g.everforest_background = 'hard'
              vim.opt.background = "dark"
            ]],
          },
          {
            name = "Kanagawa Dragon",
            colorscheme = "kanagawa-dragon",
          },
          {
            name = "Kanagawa Wave",
            colorscheme = "kanagawa-wave",
          },
          {
            name = "Moonfly",
            colorscheme = "moonfly",
          },
          {
            name = "Sonokai",
            colorscheme = "sonokai",
          },
          {
            name = "Material Deep Ocean",
            colorscheme = "material",
            before = [[
              vim.g.material_style = "deep ocean"
            ]],
          },
          {
            name = "Material Palenight",
            colorscheme = "material",
            before = [[
              vim.g.material_style = "palenight"
            ]],
          },
          {
            name = "Neosolarized Dark",
            colorscheme = "NeoSolarized",
            before = [[
              vim.opt.background = "dark"
            ]],
          },
          {
            name = "Melange",
            colorscheme = "melange",
          },
          {
            name = "Doom One",
            colorscheme = "doom-one",
          },
          {
            name = "Nightfly",
            colorscheme = "nightfly",
          },
          {
            name = "VSCode Dark",
            colorscheme = "vscode",
          },
          {
            name = "Edge Dark",
            colorscheme = "edge",
            before = [[
              vim.g.edge_style = 'neon'
              vim.opt.background = "dark"
            ]],
          },
          {
            name = "Ayu Dark",
            colorscheme = "ayu",
            before = [[
              vim.g.ayucolor = "dark"
            ]],
          },
          {
            name = "Ayu Mirage",
            colorscheme = "ayu",
            before = [[
              vim.g.ayucolor = "mirage"
            ]],
          },
          {
            name = "Nord",
            colorscheme = "nord",
          },
          {
            name = "GitHub Dark",
            colorscheme = "github_dark_default",
          },
          {
            name = "GitHub Dark Dimmed",
            colorscheme = "github_dark_dimmed",
          },
          {
            name = "Monokai Pro",
            colorscheme = "monokai-pro",
            before = [[
              vim.g.monokai_pro_filter = "spectrum"
            ]],
          },
          {
            name = "Monokai Ristretto",
            colorscheme = "monokai-pro",
            before = [[
              vim.g.monokai_pro_filter = "ristretto"
            ]],
          },
        },
        themeConfigFile = vim.fn.stdpath("data") .. "/themery.lua",
        livePreview = true,
        -- Maintain transparency setting when changing themes
        globalAfter = [[
          -- Re-apply transparency setting when changing theme
          if vim.g.transparent_enabled then
            require("transparent").enable()
          else
            require("transparent").disable()
          end
        ]],
      })
    end,
    dependencies = {
      -- Include all the vibrant dark themes
      "folke/tokyonight.nvim",
      "catppuccin/nvim",
      "ellisonleao/gruvbox.nvim",
      "navarasu/onedark.nvim",
      "EdenEast/nightfox.nvim",  -- Nightfox, Carbonfox, etc.
      "sainnhe/everforest",
      "rebelot/kanagawa.nvim",
      "bluz71/vim-moonfly-colors",
      "sainnhe/sonokai",
      "marko-cerovac/material.nvim",
      "overcache/NeoSolarized",
      "savq/melange-nvim",
      "NTBBloodbath/doom-one.nvim",
      "bluz71/vim-nightfly-colors",
      "Mofiqul/vscode.nvim",
      "sainnhe/edge",
      "Shatur/neovim-ayu",
      "shaunsingh/nord.nvim",
      "projekt0n/github-nvim-theme",
      "loctvl842/monokai-pro.nvim",
      "Mofiqul/dracula.nvim",
    },
  },
  
  -- UI plugins
  -- This helps us avoid the treesitter plugins that have Nix-related issues
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({})
    end,
  },
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup({
        lsp = {
          override = {
            ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
            ["vim.lsp.util.stylize_markdown"] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
        },
      })
    end,
  },
  
  -- Adding editor plugins
  {
    "nvim-tree/nvim-tree.lua", 
    dependencies = { "nvim-tree/nvim-web-devicons" },
    keys = {
      { "<F2>", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Toggle file explorer" },
    },
    config = function()
      require("nvim-tree").setup({
        view = {
          width = 35,
        },
        filters = {
          dotfiles = false,
        },
      })
    end,
  },
  
  -- Auto pairs
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  
  -- Comment.nvim for easy commenting
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require("Comment").setup()
    end,
  },
  
  -- Adding basic tool plugins
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { 
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Find text" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Find buffers" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Find help" },
      { "<C-p>", "<cmd>Telescope find_files<cr>", desc = "Find files (Ctrl+P)" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
      })
    end,
  },

  -- Git integration
  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function()
      require("gitsigns").setup()
    end,
  },

  -- Terminal integration
  {
    "akinsho/toggleterm.nvim",
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm<cr>", desc = "Toggle terminal" },
    },
    config = function()
      require("toggleterm").setup({
        open_mapping = [[<C-\>]],
        direction = "float",
      })
    end,
  },

  -- Basic LSP Support
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
      -- Set up Mason first
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      
      -- Configure Mason-LSPConfig
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls", -- Only install one basic server for now
        },
        automatic_installation = true,
      })
      
      -- Basic key mappings for LSP
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      
      -- Setup specific LSP servers
      local lspconfig = require('lspconfig')
      lspconfig.lua_ls.setup({
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            }
          }
        }
      })
    end,
  },
  
  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
    },
    config = function()
      local cmp = require('cmp')
      local luasnip = require('luasnip')
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ['<C-Space>'] = cmp.mapping.complete(),
          ['<CR>'] = cmp.mapping.confirm({ select = true }),
          ['<Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
            else
              fallback()
            end
          end, { 'i', 's' }),
          ['<S-Tab>'] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
              luasnip.jump(-1)
            else
              fallback()
            end
          end, { 'i', 's' }),
        }),
        sources = cmp.config.sources({
          { name = 'nvim_lsp' },
          { name = 'luasnip' },
          { name = 'buffer' },
          { name = 'path' },
        }),
      })
    end,
  }
}, {
  ui = {
    -- Make sure the UI shows up
    border = "single",
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🔑",
      plugin = "🔌",
      runtime = "💻",
      require = "🔍",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤",
    },
  },
  -- Simple configuration to minimize errors
  checker = { enabled = false },     -- Disable update checker
  change_detection = { enabled = false },  -- Disable change detection
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Status message
vim.cmd [[
  echo "Neovim loaded with 30+ themes, UI plugins, editor tools, and LSP support"
]]

-- End of configuration