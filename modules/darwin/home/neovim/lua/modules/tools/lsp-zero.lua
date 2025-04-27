-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/VonHeikemen/lsp-zero.nvim/v3.x/doc/md/lsp-zero.md"
local M = {}

M.plugins = {
  {
    "VonHeikemen/lsp-zero.nvim",
    branch = "v3.x",
    lazy = false,
    dependencies = {
      "neovim/nvim-lspconfig",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      
      -- Autocompletion
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      "saadparwaiz1/cmp_luasnip",
      "L3MON4D3/LuaSnip",
      
      -- Additional LSP plugins
      "b0o/schemastore.nvim",
      "folke/neodev.nvim"
    },
    config = function()
      local lsp_zero = require('lsp-zero')
      local lspconfig = require('lspconfig')
      local mason_lspconfig = require('mason-lspconfig')
      local neodev = require('neodev')
      local wk = require('which-key')
      
      -- Configure neodev first (must be set up before lspconfig)
      neodev.setup({})
      
      lsp_zero.preset({
        name = 'recommended',
        set_lsp_keymaps = true,
        manage_nvim_cmp = false, -- We'll configure cmp separately
        suggest_lsp_servers = true,
      })
      
      -- Configure mason for automated LSP installation
      require('mason').setup({
        ui = {
          border = 'rounded',
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗"
          }
        }
      })
      
      -- Ensure required LSP servers are installed via mason-lspconfig
      do
        local mlsp = mason_lspconfig
        local servers = {
          -- Go
          "gopls",
          "golangci_lint_ls",
          -- Shell
          "bashls",
          -- Data formats
          "hydra_lsp",
          -- Markdown
          "marksman",
          "grammarly",
          -- Terraform
          "tflint",
          "terraformls",
          -- Helm
          "helm-ls",
        }
        local to_install = {}
        if mlsp.get_available_servers then
          local available = mlsp.get_available_servers()
          for _, name in ipairs(servers) do
            if vim.tbl_contains(available, name) then
              table.insert(to_install, name)
            end
          end
        else
          to_install = servers
        end
        mlsp.setup({ ensure_installed = to_install })
      end

      -- Setup handlers for LSP configurations
      mason_lspconfig.setup_handlers({
        lsp_zero.default_setup,

        -- Lua Configuration
        lua_ls = function()
          lspconfig.lua_ls.setup(lsp_zero.nvim_lua_ls())
        end,

        -- Go Configuration
        gopls = function()
          lspconfig.gopls.setup({
            settings = {
              gopls = {
                analyses = {
                  unusedparams = true,
                  shadow = true,
                },
                staticcheck = true,
                gofumpt = true,
                usePlaceholders = true,
                completeUnimported = true,
              },
            },
            capabilities = lsp_zero.get_capabilities(),
          })
        end,
      })

      -- Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = {
          prefix = '●',
          source = 'if_many',
        },
        float = {
          border = 'rounded',
          source = 'always',
        },
        severity_sort = true,
        update_in_insert = false,
      })
      
    end
  }
}

return M