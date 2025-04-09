-- Configure package path
do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

-- Set up system-specific configurations
-- Handle Nix-specific settings
if vim.fn.isdirectory('/nix') == 1 then
  -- Set up parsers path for treesitter that's writable
  -- This avoids the permission denied error in Nix store
  vim.g.nix_system = true
  -- Create a local directory for parsers that's writable
  vim.opt.runtimepath:append(vim.fn.stdpath('data') .. '/treesitter')
  vim.g.treesitter_parsers_path = vim.fn.stdpath('data') .. '/treesitter/parsers'
  vim.cmd([[set rtp+=]] .. vim.fn.stdpath('data') .. '/treesitter')
  
  -- Create the directory if it doesn't exist
  if vim.fn.isdirectory(vim.fn.stdpath('data') .. '/treesitter/parsers') == 0 then
    vim.fn.mkdir(vim.fn.stdpath('data') .. '/treesitter/parsers', 'p')
  end
end

-- PHASE 3: Add core modules
-- Load core options and keymaps from modules
-- Use pcall to ensure errors don't stop execution
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
  
  -- Colorscheme
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd[[colorscheme tokyonight]]
    end,
  },
  
  -- Import selected plugin modules
  -- Add more imports as we verify each one works
  
  -- Use individual UI plugins instead of importing the whole module
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
  echo "Neovim configuration loaded with UI, editor, tools, and LSP support"
]]

-- Exit automatically in headless mode after config is loaded
if #vim.api.nvim_list_uis() == 0 then
  vim.cmd("qa!")
end