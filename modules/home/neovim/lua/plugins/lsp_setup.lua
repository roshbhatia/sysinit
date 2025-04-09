return {
  -- LSP Configuration & Plugins
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      -- Automatically install LSPs and related tools to stdpath
      { "williamboman/mason.nvim" },
      { "williamboman/mason-lspconfig.nvim" },
      { "WhoIsSethDaniel/mason-tool-installer.nvim" },
      
      -- Useful status updates for LSP
      { "j-hui/fidget.nvim", opts = {} },
      
      -- Additional lua configuration, makes nvim stuff amazing!
      { "folke/neodev.nvim" },
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Setup neovim lua configuration
      require("neodev").setup()
      
      -- Setup mason so it can manage external tooling
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

      -- Enable the following language servers
      local servers = {
        -- Languages
        lua_ls = {
          settings = {
            Lua = {
              diagnostics = { globals = { "vim" } },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
              },
              telemetry = { enable = false },
            },
          },
        },
        bashls = {},       -- Bash
        gopls = {},        -- Go
        pyright = {},      -- Python
        rust_analyzer = {  -- Rust
          settings = {
            ['rust-analyzer'] = {
              checkOnSave = {
                command = "clippy",
              },
              cargo = {
                allFeatures = true,
              },
            },
          },
        },
        tsserver = {},     -- TypeScript/JavaScript
        html = {},         -- HTML
        cssls = {},        -- CSS
        jsonls = {},       -- JSON
        yamlls = {         -- YAML
          settings = {
            yaml = {
              schemaStore = { enable = true },
              validate = true,
              completion = true,
              hover = true,
            },
          },
        },
        terraformls = {},  -- Terraform
        tflint = {},       -- Terraform Linting
        clangd = {},       -- C/C++
        cmake = {},        -- CMake
        zls = {},          -- Zig
        nil_ls = {},       -- Nix 
        helm_ls = {},      -- Helm
        taplo = {},        -- TOML
        
        -- Kubernetes related
        kubernetes_analyzer = {}, -- Kubernetes manifests
        
        -- Additional LSPs as needed
      }

      -- nvim-cmp supports additional completion capabilities, so broadcast that to servers
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)

      -- Ensure the servers from above are installed
      local mason_lspconfig = require("mason-lspconfig")
      
      mason_lspconfig.setup({
        ensure_installed = vim.tbl_keys(servers),
        automatic_installation = true,
      })
      
      -- Additional tools to install through Mason
      require("mason-tool-installer").setup({
        ensure_installed = {
          -- Linters
          "shellcheck",               -- Shell script linting
          "golangci-lint",            -- Go linting
          "eslint_d",                 -- JS/TS linting
          "flake8",                   -- Python linting
          "pylint",                   -- Python linting
          "hadolint",                 -- Dockerfile linting
          "markdownlint",             -- Markdown linting
          "yamllint",                 -- YAML linting
          "stylelint",                -- CSS linting
          "jsonlint",                 -- JSON linting
          "cpplint",                  -- C/C++ linting
          "curlylint",                -- HTML templates linting
          
          -- Formatters
          "stylua",                   -- Lua formatter
          "black",                    -- Python formatter
          "isort",                    -- Python import sorter
          "prettier",                 -- JS/TS/HTML/CSS/JSON formatter
          "shfmt",                    -- Shell formatter
          "gofumpt",                  -- Go formatter
          "goimports",                -- Go imports formatter
          "rustfmt",                  -- Rust formatter
          "clang-format",             -- C/C++ formatter
          "nixfmt",                   -- Nix formatter
          "terraform-fmt",            -- Terraform formatter
          "zigfmt",                   -- Zig formatter
          "taplo",                    -- TOML formatter
          
          -- Additional tools
          "kube-linter",              -- Kubernetes linting
          "helmls",                   -- Helm chart linting
          "kubectl",                  -- Kubernetes CLI
          "kustomize",                -- Kubernetes customization
          "js-debug-adapter",         -- JS debugging
          "codelldb",                 -- C/C++/Rust debugging
        },
      })

      -- Set up visual indicators for diagnostics
      local signs = {
        { name = "DiagnosticSignError", text = "󰅚" },
        { name = "DiagnosticSignWarn", text = "󰀪" },
        { name = "DiagnosticSignHint", text = "󰌶" },
        { name = "DiagnosticSignInfo", text = "󰋽" },
      }
      
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, {
          texthl = sign.name,
          text = sign.text,
          numhl = "",
        })
      end
      
      -- Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●", 
          source = "if_many",
        },
        signs = { active = signs },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
        float = {
          focusable = false,
          style = "minimal",
          border = "rounded",
          source = "always",
          header = "",
          prefix = "",
        },
      })
      
      -- Function to set up common mappings for all language servers
      local on_attach = function(client, bufnr)
        -- Set up buffer-local mappings
        local opts = { buffer = bufnr, noremap = true, silent = true }
        
        vim.keymap.set("n", "gd", function() require("cinnamon").scroll(vim.lsp.buf.definition) end, 
                      { buffer = bufnr, desc = "󰞙 Go to definition (smooth)" })
        vim.keymap.set("n", "gD", function() require("cinnamon").scroll(vim.lsp.buf.declaration) end, 
                      { buffer = bufnr, desc = "󰞙 Go to declaration (smooth)" })
        vim.keymap.set("n", "gi", function() require("cinnamon").scroll(vim.lsp.buf.implementation) end, 
                      { buffer = bufnr, desc = "󰡱 Go to implementation (smooth)" })
        vim.keymap.set("n", "gr", function() require("cinnamon").scroll(vim.lsp.buf.references) end, 
                      { buffer = bufnr, desc = "󰮍 Find references" })
        vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "󰖨 Show hover docs" })
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "󰛨 Code actions" })
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, { buffer = bufnr, desc = "󰛿 Rename symbol" })
        vim.keymap.set("n", "<leader>cf", function() vim.lsp.buf.format({ async = true }) end, 
                      { buffer = bufnr, desc = "󰉶 Format document" })
        vim.keymap.set("n", "<leader>cd", vim.diagnostic.open_float, { buffer = bufnr, desc = "󱌲 Line diagnostics" })
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, { buffer = bufnr, desc = "󰝤 Previous diagnostic" })
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, { buffer = bufnr, desc = "󰝦 Next diagnostic" })
      end

      -- Setup all servers with custom settings as defined above
      mason_lspconfig.setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = capabilities,
            on_attach = on_attach,
            settings = servers[server_name] and servers[server_name].settings,
            filetypes = servers[server_name] and servers[server_name].filetypes,
            root_dir = servers[server_name] and servers[server_name].root_dir,
          })
        end,
      })
    end,
  },

  -- Autocompletion
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      -- Sources
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      
      -- Snippets
      "L3MON4D3/LuaSnip",
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
      
      -- Icons for completion
      "onsails/lspkind.nvim",
    },
    event = { "InsertEnter", "CmdlineEnter" },
    config = function()
      local cmp = require("cmp")
      local luasnip = require("luasnip")
      local lspkind = require("lspkind")
      
      -- Load friendly-snippets
      require("luasnip.loaders.from_vscode").lazy_load()
      
      cmp.setup({
        snippet = {
          expand = function(args)
            luasnip.lsp_expand(args.body)
          end,
        },
        mapping = cmp.mapping.preset.insert({
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
          { name = "buffer" },
          { name = "path" },
        }),
        formatting = {
          format = lspkind.cmp_format({
            mode = "symbol_text",
            maxwidth = 50,
            ellipsis_char = "...",
            symbol_map = {
              Text = "󰉿",
              Method = "󰆧",
              Function = "󰊕",
              Constructor = "",
              Field = "󰜢",
              Variable = "󰀫",
              Class = "󰠱",
              Interface = "",
              Module = "",
              Property = "󰜢",
              Unit = "󰑭",
              Value = "󰎠",
              Enum = "",
              Keyword = "󰌋",
              Snippet = "",
              Color = "󰏘",
              File = "󰈙",
              Reference = "󰈇",
              Folder = "󰉋",
              EnumMember = "",
              Constant = "󰏿",
              Struct = "󰙅",
              Event = "",
              Operator = "󰆕",
              TypeParameter = "󰊄",
            },
          }),
        },
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
        experimental = {
          ghost_text = true,
        },
      })
      
      -- Set up cmdline completion
      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({
          { name = "path" },
          { name = "cmdline" },
        }),
      })
      
      -- Set up search completion
      cmp.setup.cmdline("/", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = {
          { name = "buffer" },
        },
      })
    end,
  },

  -- Trouble for better diagnostics display
  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "Trouble", "TroubleToggle" },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "󱌲 Document diagnostics" },
      { "<leader>xw", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "󱌳 Workspace diagnostics" },
      { "<leader>xl", "<cmd>TroubleToggle loclist<cr>", desc = "󰑊 Location list" },
      { "<leader>xq", "<cmd>TroubleToggle quickfix<cr>", desc = "󰑓 Quickfix list" },
    },
    opts = {
      position = "bottom",
      height = 15,
      width = 50,
      icons = true,
      mode = "workspace_diagnostics",
      fold_open = "󰅀",
      fold_closed = "󰅂",
      group = true,
      padding = true,
      action_keys = {
        close = "q",
        cancel = "<esc>",
        refresh = "r",
        jump = { "<cr>", "<tab>" },
        open_split = { "<c-s>" },
        open_vsplit = { "<c-v>" },
        open_tab = { "<c-t>" },
        jump_close = { "o" },
        toggle_mode = "m",
        toggle_preview = "P",
        hover = "K",
        preview = "p",
        close_folds = { "zM", "zm" },
        open_folds = { "zR", "zr" },
        toggle_fold = { "zA", "za" },
        previous = "k",
        next = "j"
      },
      indent_lines = true,
      auto_open = false,
      auto_close = false,
      auto_preview = true,
      auto_fold = false,
      signs = {
        error = "󰅚",
        warning = "󰀪",
        hint = "󰌶",
        information = "󰋽",
        other = "󰗡"
      },
      use_diagnostic_signs = false
    },
  },
}