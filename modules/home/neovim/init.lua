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

-- Get the directory of the current init.lua file
local init_dir = vim.fn.fnamemodify(vim.fn.expand("$MYVIMRC"), ":p:h")
-- Add the lua directory relative to the init.lua location
local lua_dir = init_dir .. "/lua"
vim.opt.rtp:prepend(lua_dir)

-- Set leader key
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Set Shift+Space as command line trigger
vim.keymap.set('n', '<S-Space>', ':', { noremap = true })

-- Explicitly register space key to do nothing (prevents default space behavior)
vim.keymap.set('n', '<Space>', '<NOP>')

-- Basic editor settings
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.termguicolors = true
vim.opt.showmode = false  -- Hide mode since we use lualine

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
vim.opt.lazyredraw = true

-- Scrolling
vim.opt.scrolloff = 8
vim.opt.sidescrolloff = 8

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

-- Other options
vim.opt.mouse = "a"
vim.opt.completeopt = { "menuone", "noselect" }
vim.opt.clipboard = "unnamedplus"  -- Use system clipboard

-- Define module categories and their modules
local module_system = {
  -- Core editor functionality - loaded first to ensure dependencies are available
  editor = {
    "which-key", -- Load which-key first as it will define key mappings centrally
    "telescope",
    "oil",
    "wilder",
  },
  -- UI-related modules
  ui = {
    "bufferline",
    "carbonfox",
    "devicons",
    "lualine",
    "wezterm",
    "nvimtree",
  },
  -- Tool modules that enhance editing experience
  tools = {
    "comment",
    "hop",
    "treesitter",
  }
}

-- Collect plugin specs from all modules
local function collect_plugin_specs()
  local specs = {}
  
  -- Process modules in specific order to handle dependencies correctly
  local categories = {"editor", "ui", "tools"}
  
  for _, category in ipairs(categories) do
    for _, module_name in ipairs(module_system[category]) do
      local ok, module = pcall(require, "modules." .. category .. "." .. module_name)
      if ok and module.plugins then
        vim.list_extend(specs, module.plugins)
      end
    end
  end
  
  -- Add LSP and completion plugins
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
  
  return specs
end

-- Setup Lazy.nvim with collected specs
require("lazy").setup(collect_plugin_specs())