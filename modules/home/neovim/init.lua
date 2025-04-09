do
  local config_path = vim.fn.expand('<sfile>:p:h')
  package.path = config_path .. '/lua/?.lua;' .. 
                 config_path .. '/lua/?/init.lua;' .. 
                 package.path
end

local options_ok, _ = pcall(require, "core.options")
if not options_ok then
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
  vim.opt.lazyredraw = false     -- Explicitly disable lazyredraw for noice.nvim compatibility
  vim.opt.shada = "'1000,f1,<500,:100,/100,h"  -- Fix for startify viminfo
  
  print("Using fallback options (core.options not loaded)")
end

vim.g.mapleader = " "

-- Fix for startify
vim.g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
vim.g.startify_session_autoload = 1
vim.g.startify_session_persistence = 1
vim.g.startify_session_delete_buffers = 1
vim.g.startify_skiplist = {"COMMIT_EDITMSG"}
vim.g.startify_enable_special = 0
vim.g.startify_custom_indices = {'a', 'b', 'c', 'd', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'}

-- Add keymap for toggle modifiable
vim.keymap.set('n', '<leader>tm', function()
  vim.opt.modifiable = not vim.opt.modifiable:get()
  print("Modifiable: " .. (vim.opt.modifiable:get() and "ON" or "OFF"))
end, { desc = "Toggle modifiable" })

-- For macOS users - fix cmd+a
if vim.fn.has('mac') == 1 then
  vim.keymap.set('n', '<D-a>', 'ggVG', { noremap = true, silent = true, desc = "Select all text" })
  vim.keymap.set('i', '<D-a>', '<Esc>ggVG', { noremap = true, silent = true, desc = "Select all text" })
  vim.keymap.set('v', '<D-a>', 'ggVG', { noremap = true, silent = true, desc = "Select all text" })
end

local keymaps_ok, _ = pcall(require, "core.keymaps")
if not keymaps_ok then
  vim.keymap.set('n', '<leader>w', ':w<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>q', ':q<CR>', { noremap = true, silent = true })
  vim.keymap.set('n', '<leader>Q', ':qa!<CR>', { noremap = true, silent = true })
  
  print("Using fallback keymaps (core.keymaps not loaded)")
end

local autocmd_ok, _ = pcall(require, "core.autocmds")
if not autocmd_ok then
  print("Note: core.autocmds not loaded (this is normal for initial testing)")
  
  -- Add autocmd for lazy.nvim dialog
  vim.api.nvim_create_autocmd("FileType", {
    pattern = {"lazy", "help"},
    callback = function()
      vim.keymap.set("n", "q", "<cmd>close<CR>", { buffer = true, noremap = true, silent = true })
      vim.keymap.set("n", "<Esc>", "<cmd>close<CR>", { buffer = true, noremap = true, silent = true })
    end,
  })
end

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

vim.keymap.set('n', '<leader>l', ':Lazy<CR>', { noremap = true, silent = true, desc = "Open Lazy.nvim" })

require("lazy").setup({
  -- Add support for loading plugins from the lua/plugins directory
  { import = "plugins" },
  
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    init = function()
      vim.o.timeout = true
      vim.o.timeoutlen = 300
    end,
    opts = {},
  },
  
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
      require("transparent").clear_prefix("BufferLine")
      vim.g.transparent_enabled = false
    end,
  },
  
  {
    "zaldih/themery.nvim",
    lazy = false,
    keys = {
      { "<leader>tt", "<cmd>Themery<CR>", desc = "Switch Theme" },
    },
    config = function()
      _G.toggle_transparency = function()
        -- Fix the toggle function by ensuring transparent is loaded and available
        local transparent_ok, transparent = pcall(require, "transparent")
        if not transparent_ok then
          print("Transparent plugin not available")
          return
        end
        
        vim.g.transparent_enabled = not vim.g.transparent_enabled
        if vim.g.transparent_enabled then
          transparent.enable()
          print("Transparency enabled")
        else
          transparent.disable()
          print("Transparency disabled")
        end
      end
      
      vim.api.nvim_set_keymap("n", "<leader>tp", [[<cmd>lua toggle_transparency()<CR>]], { noremap = true, silent = true, desc = "Toggle transparency" })
      
      require("themery").setup({
        themes = {
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
        livePreview = true,
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
      "folke/tokyonight.nvim",
      "catppuccin/nvim",
      "ellisonleao/gruvbox.nvim",
      "navarasu/onedark.nvim",
      "EdenEast/nightfox.nvim",
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
  
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        plugins = {
          spelling = {
            enabled = true,
            suggestions = 20,
          },
        },
        window = {
          border = "single",
          padding = { 1, 1, 1, 1 },
        },
        layout = {
          height = { min = 3, max = 25 }, 
          width = { min = 20, max = 50 },
          spacing = 3,
          align = "center",
        },
        icons = {
          breadcrumb = "»",
          separator = "➜",
          group = "󰉂 ",
        },
        -- Hide keymaps with <Plug> and empty labels
        ignore_missing = false,
        hidden = { "<silent>", "<cmd>", "<Cmd>", "<CR>", "call", "lua", "^:", "^ " },
        show_help = true,
        show_keys = true,
        triggers = "auto",
        -- Add custom labels with icons
        triggers_blacklist = {
          i = { "j", "k" },
          v = { "j", "k" },
        },
      })

      -- Add custom groups with icons
      local wk = require("which-key")
      wk.register({
        ["<leader>f"] = { name = "󰈬 Files/Find" },
        ["<leader>b"] = { name = "󰓥 Buffers" },
        ["<leader>w"] = { name = "󰘥 Windows" },
        ["<leader>g"] = { name = "󰑲 Git" },
        ["<leader>h"] = { name = "󰉧 Harpoon" },
        ["<leader>t"] = { name = "󰄿 Toggle" },
        ["<leader>c"] = { name = "󰈨 Code" },
        ["<leader>d"] = { name = "󰐅 Debug" },
        ["<leader>s"] = { name = "󰁰 Session" },
        ["<leader>r"] = { name = "󰒀 Refactor" },
      })
    end,
  },
  {
    "folke/noice.nvim",
    enabled = false, -- Disabled in favor of our custom config in plugins/no-notify.lua
  },
  
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
  
  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = function()
      require("nvim-autopairs").setup({})
    end,
  },
  
  {
    "numToStr/Comment.nvim",
    event = "VeryLazy",
    config = function()
      require("Comment").setup()
    end,
  },
  
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

  {
    "lewis6991/gitsigns.nvim",
    event = "BufReadPre",
    config = function()
      require("gitsigns").setup()
    end,
  },

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

  {
    "mhinz/vim-startify",
    lazy = false,
    priority = 100,
    config = function()
      -- Load the custom Startify configuration
      local startify_ok, startify = pcall(require, "config.startify")
      if startify_ok then
        startify.setup()
      else
        -- Basic startify config if custom module fails
        vim.g.startify_session_dir = vim.fn.stdpath("data") .. "/sessions"
        vim.g.startify_session_autoload = 1
        vim.g.startify_session_persistence = 1
        vim.g.startify_session_delete_buffers = 1
        vim.g.startify_change_to_dir = 1
        vim.g.startify_fortune_use_unicode = 1
        vim.g.startify_files_number = 5
        vim.g.startify_padding_left = 3
      
        -- Use vim commands directly to configure Startify
        vim.cmd([[function! s:gitModified()
            let files = systemlist('git ls-files -m 2>/dev/null')
            return map(files, "{'line': v:val, 'path': v:val}")
          endfunction

          function! s:gitUntracked()
            let files = systemlist('git ls-files -o --exclude-standard 2>/dev/null')
            return map(files, "{'line': v:val, 'path': v:val}")
          endfunction

          function! s:listRepos()
            let output = []
            let repos = systemlist('find ~/github/personal/*/. -maxdepth 1 -type d 2>/dev/null')
            for repo in repos
              let reponame = fnamemodify(repo, ':h:t') . '/' . fnamemodify(repo, ':t')
              call add(output, {'line': '  ' . reponame, 'path': repo})
            endfor
            return output
          endfunction
          
          let g:startify_lists = [
              \ { 'type': 'dir',       'header': ['   Current Directory:'] },
              \ { 'type': 'files',     'header': ['   Recent Files:'] },
              \ { 'type': 'sessions',  'header': ['   Sessions'] },
              \ { 'type': 'bookmarks', 'header': ['   Bookmarks'] },
              \ { 'type': 'commands',  'header': ['   Commands'] },
              \ { 'type': function('s:gitModified'),  'header': ['   Git Modified:'] },
              \ { 'type': function('s:gitUntracked'), 'header': ['   Git Untracked:'] },
              \ { 'type': function('s:listRepos'),    'header': ['   Repositories:'] },
              \ ]
        ]])
        
        -- Custom ASCII art header for Startify
        vim.g.startify_custom_header = {
          "⠀⠀⠀⠀⠀⠀⠐⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
          "⠀⠀⠀⠀⠀⠀⠈⣾⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
          "⠀⠀⠀⠀⠀⠀⠀⢸⣇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
          "⠀⠀⠀⠀⠀⠀⠀⣈⣼⣄⣠⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
        }
      end
    end,
  },
  
  -- Add Treesitter for syntax highlighting and code parsing
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("nvim-treesitter.configs").setup({
        ensure_installed = {
          "bash", "c", "cpp", "css", "go", "html", "java", "javascript", 
          "json", "lua", "markdown", "markdown_inline", "python", "regex", 
          "rust", "tsx", "typescript", "vim", "vimdoc", "yaml",
        },
        auto_install = true,
        highlight = { 
          enable = true,
          -- Disable on large files for performance
          disable = function(_, buf)
            local max_filesize = 100 * 1024 -- 100 KB
            local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
            if ok and stats and stats.size > max_filesize then
              return true
            end
          end,
          additional_vim_regex_highlighting = false,
        },
        indent = { enable = true },
      })
    end,
  },

  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
    },
    config = function()
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
      
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
        },
        automatic_installation = true,
      })
      
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {})
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {})
      vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, {})
      
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
  checker = { enabled = false },
  change_detection = { enabled = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin",
      },
    },
  },
})

-- Load additional configurations
local image_preview_ok, image_preview = pcall(require, "config.image_preview")
if image_preview_ok then
  image_preview.setup()
end

-- Silent startup
vim.opt.shortmess:append("I")