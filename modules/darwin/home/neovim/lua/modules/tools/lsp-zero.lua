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
          -- Lua
          "lua_ls",
          "luacheck",
          "luaformatter",
          
          -- Go
          "gopls",
          "delve",
          "gotests",
          "gotestsum",
          "json-to-struct",
          
          -- Python
          "pyright",
          
          -- JS/TS
          "eslint",
          "typescript-language-server", -- instead of ts_server or ts_ls
          
          -- Shell
          "bashls",
          "shellcheck",
          
          -- Data formats
          "jsonls",
          "jsonlint",
          "jsonnet-language-server",
          "yamlls",
          "yamllint",
          "yamlfmt",
          "yamlfix",
          "taplo",
          "yq",
          
          -- Markdown
          "marksman",
          "grammarly-languageserver",
          
          -- Nix
          "nixfmt",
          "nixpkgs-fmt",
          
          -- Terraform
          "tflint",
          
          -- HCL
          "hclfmt",
          
          -- Helm
          "helm-ls",
          
          -- Git
          "actionlint",
          "commitlint",
          
          -- Other
          "gospel",
        }
        local to_install = {}
        if mlsp.get_available_servers then
          local available = mlsp.get_available_servers()
          for _, name in ipairs(servers) do
            if vim.tbl_contains(available, name) then
              table.insert(to_install, name)
            else
              vim.notify("LSP server '" .. name .. "' not available in mason-lspconfig, skipping", vim.log.levels.WARN)
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

        -- Python Configuration
        pyright = function()
          lspconfig.pyright.setup({
            settings = {
              python = {
                analysis = {
                  autoSearchPaths = true,
                  diagnosticMode = "workspace",
                  useLibraryCodeForTypes = true,
                },
              },
            },
            capabilities = lsp_zero.get_capabilities(),
          })
        end,

        -- YAML Configuration with schema support
        yamlls = function()
          lspconfig.yamlls.setup({
            settings = {
              yaml = {
                schemaStore = {
                  enable = false,
                  url = "",
                },
                schemas = require('schemastore').yaml.schemas(),
                validate = true,
                format = { enable = true },
              },
            },
            capabilities = lsp_zero.get_capabilities(),
          })
        end,

        -- JSON Configuration with schema support
        jsonls = function()
          lspconfig.jsonls.setup({
            settings = {
              json = {
                schemas = require('schemastore').json.schemas(),
                validate = { enable = true },
              },
            },
            capabilities = lsp_zero.get_capabilities(),
          })
        end,
      })
      
      -- Global keymappings
      lsp_zero.on_attach(function(client, bufnr)
        -- Default LSP mappings
        lsp_zero.default_keymaps({buffer = bufnr})
        
        -- Custom keymappings
        local opts = {buffer = bufnr}
        vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
        vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
        vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
        vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
        vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
        vim.keymap.set('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
        vim.keymap.set('n', '<leader>do', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
        vim.keymap.set('n', '<leader>dp', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
        vim.keymap.set('n', '<leader>dn', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
        
        -- Set buffer-local which-key mappings for LSP features
        wk.add({
          { "gd", "<cmd>lua vim.lsp.buf.definition()<cr>", desc = "Go to Definition", buffer = bufnr },
          { "gr", "<cmd>lua vim.lsp.buf.references()<cr>", desc = "Go to References", buffer = bufnr },
          { "gi", "<cmd>lua vim.lsp.buf.implementation()<cr>", desc = "Go to Implementation", buffer = bufnr },
          { "K", "<cmd>lua vim.lsp.buf.hover()<cr>", desc = "Show Hover", buffer = bufnr },
          { "<leader>d", group = "Diagnostics", icon = { icon = "󰨮", hl = "WhichKeyIconRed" }, buffer = bufnr },
          { "<leader>do", "<cmd>lua vim.diagnostic.open_float()<cr>", desc = "Show Diagnostics", buffer = bufnr },
          { "<leader>dp", "<cmd>lua vim.diagnostic.goto_prev()<cr>", desc = "Previous Diagnostic", buffer = bufnr },
          { "<leader>dn", "<cmd>lua vim.diagnostic.goto_next()<cr>", desc = "Next Diagnostic", buffer = bufnr },
          { "<leader>r", group = "Refactor", icon = { icon = "󰕚", hl = "WhichKeyIconBlue" }, buffer = bufnr },
          { "<leader>rn", "<cmd>lua vim.lsp.buf.rename()<cr>", desc = "Rename Symbol", buffer = bufnr },
          { "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", desc = "Code Action", buffer = bufnr },
        })
      end)
      
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
      
      -- Enable LSP inlay hints (for supported servers)
      if vim.lsp.inlay_hint then
        vim.keymap.set('n', '<leader>ih', function()
          vim.lsp.inlay_hint.enable(0, not vim.lsp.inlay_hint.is_enabled())
        end, { desc = "Toggle Inlay Hints" })
      end
    end
  }
}

return M