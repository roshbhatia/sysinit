-- LSP Configuration
-- Main LSP setup file

return {
  -- Mason for LSP, DAP, linter, and formatter management
  {
    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = {
      { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" },
    },
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = {
            package_installed = "✓",
            package_pending = "➜",
            package_uninstalled = "✗",
          },
        },
      })
    end,
  },
  
  -- Mason LSP configuration
  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "neovim/nvim-lspconfig",
      "ms-jpq/coq_nvim",
    },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",          -- Lua
          "pyright",         -- Python
          "tsserver",        -- TypeScript/JavaScript
          "jsonls",          -- JSON
          "yamlls",          -- YAML
          "gopls",           -- Go
          "rust_analyzer",   -- Rust
          "bashls",          -- Bash
          "clangd",          -- C/C++
          "html",            -- HTML
          "cssls",           -- CSS
          "dockerls",        -- Docker
          "eslint",          -- ESLint
          "marksman",        -- Markdown
          "tailwindcss",     -- Tailwind CSS
        },
        automatic_installation = true,
      })
      
      -- Get coq
      local coq = require("coq")
      
      -- LSP setup
      local lspconfig = require("lspconfig")
      
      -- Common capabilities
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.textDocument.completion.completionItem.snippetSupport = true
      capabilities.textDocument.completion.completionItem.resolveSupport = {
        properties = {
          "documentation",
          "detail",
          "additionalTextEdits",
        },
      }
      
      -- Common on_attach function
      local on_attach = function(client, bufnr)
        -- Enable completion triggered by <c-x><c-o>
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
        
        -- Key mappings
        local bufopts = { noremap = true, silent = true, buffer = bufnr }
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, bufopts)
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, bufopts)
        vim.keymap.set("n", "K", vim.lsp.buf.hover, bufopts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, bufopts)
        vim.keymap.set("n", "<C-k>", vim.lsp.buf.signature_help, bufopts)
        vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, bufopts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, bufopts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, bufopts)
        vim.keymap.set("n", "<leader>cf", function() vim.lsp.buf.format { async = true } end, bufopts)
        vim.keymap.set("n", "<leader>cl", vim.diagnostic.open_float, bufopts)
        vim.keymap.set("n", "[d", vim.diagnostic.goto_prev, bufopts)
        vim.keymap.set("n", "]d", vim.diagnostic.goto_next, bufopts)
        
        -- Document highlight
        if client.server_capabilities.documentHighlightProvider then
          vim.api.nvim_create_augroup("lsp_document_highlight", { clear = true })
          vim.api.nvim_clear_autocmds({ group = "lsp_document_highlight", buffer = bufnr })
          vim.api.nvim_create_autocmd("CursorHold", {
            callback = vim.lsp.buf.document_highlight,
            buffer = bufnr,
            group = "lsp_document_highlight",
            desc = "Document Highlight",
          })
          vim.api.nvim_create_autocmd("CursorMoved", {
            callback = vim.lsp.buf.clear_references,
            buffer = bufnr,
            group = "lsp_document_highlight",
            desc = "Clear All the References",
          })
        end
      end
      
      -- Set up lspconfig
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          lspconfig[server_name].setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            capabilities = capabilities,
          }))
        end,
        
        -- Custom LSP configurations
        ["lua_ls"] = function()
          lspconfig.lua_ls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              Lua = {
                diagnostics = {
                  globals = { "vim" },
                },
                workspace = {
                  library = {
                    [vim.fn.expand("$VIMRUNTIME/lua")] = true,
                    [vim.fn.stdpath("config") .. "/lua"] = true,
                  },
                },
                telemetry = {
                  enable = false,
                },
              },
            },
          }))
        end,
        
        ["pyright"] = function()
          lspconfig.pyright.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              python = {
                analysis = {
                  typeCheckingMode = "off",
                  autoSearchPaths = true,
                  useLibraryCodeForTypes = true,
                  diagnosticMode = "workspace",
                },
              },
            },
          }))
        end,
        
        ["jsonls"] = function()
          lspconfig.jsonls.setup(coq.lsp_ensure_capabilities({
            on_attach = on_attach,
            capabilities = capabilities,
            settings = {
              json = {
                schemas = require("schemastore").json.schemas(),
                validate = { enable = true },
              },
            },
          }))
        end,
      })
    end,
  },
  
  -- LSP support
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "b0o/schemastore.nvim",
      "folke/neodev.nvim",
    },
  },
  
  -- Enhanced LSP UI
  {
    "nvimdev/lspsaga.nvim",
    event = "LspAttach",
    config = function()
      require("lspsaga").setup({
        ui = {
          border = "rounded",
          title = true,
          winblend = 0,
          expand = "",
          collapse = "",
          code_action = "💡",
          diagnostic = "🔍",
          incoming = " ",
          outgoing = " ",
          lines = { "┗", "┣", "┃", "━", "┏" },
          kind = {},
        },
        symbol_in_winbar = {
          enable = true,
          separator = " › ",
          hide_keyword = true,
          show_file = true,
          folder_level = 2,
          respect_root = false,
          color_mode = true,
        },
        definition = {
          width = 0.6,
          height = 0.6,
          keys = {
            edit = "<C-c>o",
            vsplit = "<C-c>v",
            split = "<C-c>s",
            tabe = "<C-c>t",
            quit = "q",
            close = "<Esc>",
          },
        },
        code_action = {
          num_shortcut = true,
          keys = {
            quit = "q",
            exec = "<CR>",
          },
          extend_gitsigns = true,
        },
        diagnostic = {
          show_code_action = true,
          show_source = true,
          jump_num_shortcut = true,
          max_width = 0.8,
          max_height = 0.6,
          text_hl_follow = false,
          border_follow = false,
          keys = {
            exec_action = "o",
            quit = "q",
            go_action = "g",
          },
        },
        rename = {
          quit = "<C-c>",
          exec = "<CR>",
          mark = "x",
          confirm = "<CR>",
          in_select = true,
          whole_project = true,
        },
        outline = {
          win_position = "right",
          win_width = 30,
          auto_preview = true,
          detail = true,
          auto_close = true,
          close_after_jump = false,
          layout = "normal",
          max_height = 0.5,
          keys = {
            jump = "o",
            quit = "q",
            expand_collapse = "u",
          },
        },
        callhierarchy = {
          layout = "float",
          keys = {
            edit = "e",
            vsplit = "v",
            split = "s",
            tabe = "t",
            quit = "q",
            expand_collapse = "u",
            jump = "<CR>",
          },
        },
        implement = {
          enable = true,
          sign = true,
          virtual_text = true,
          priority = 100,
        },
        lightbulb = {
          enable = true,
          sign = true,
          virtual_text = true,
          debounce = 10,
          sign_priority = 40,
        },
      })
      
      -- Keybindings
      vim.keymap.set("n", "gh", "<cmd>Lspsaga lsp_finder<CR>", { desc = "LSP Finder" })
      vim.keymap.set("n", "gp", "<cmd>Lspsaga peek_definition<CR>", { desc = "Peek Definition" })
      vim.keymap.set("n", "gt", "<cmd>Lspsaga peek_type_definition<CR>", { desc = "Peek Type Definition" })
      vim.keymap.set("n", "<leader>sl", "<cmd>Lspsaga show_line_diagnostics<CR>", { desc = "Line Diagnostics" })
      vim.keymap.set("n", "<leader>sc", "<cmd>Lspsaga show_cursor_diagnostics<CR>", { desc = "Cursor Diagnostics" })
      vim.keymap.set("n", "<leader>sb", "<cmd>Lspsaga show_buf_diagnostics<CR>", { desc = "Buffer Diagnostics" })
      vim.keymap.set("n", "[e", "<cmd>Lspsaga diagnostic_jump_prev<CR>", { desc = "Previous Diagnostic" })
      vim.keymap.set("n", "]e", "<cmd>Lspsaga diagnostic_jump_next<CR>", { desc = "Next Diagnostic" })
      vim.keymap.set("n", "[E", function()
        require("lspsaga.diagnostic"):goto_prev({ severity = vim.diagnostic.severity.ERROR })
      end, { desc = "Previous Error" })
      vim.keymap.set("n", "]E", function()
        require("lspsaga.diagnostic"):goto_next({ severity = vim.diagnostic.severity.ERROR })
      end, { desc = "Next Error" })
      vim.keymap.set("n", "<leader>o", "<cmd>Lspsaga outline<CR>", { desc = "Toggle Outline" })
      vim.keymap.set("n", "<leader>ci", "<cmd>Lspsaga incoming_calls<CR>", { desc = "Incoming Calls" })
      vim.keymap.set("n", "<leader>co", "<cmd>Lspsaga outgoing_calls<CR>", { desc = "Outgoing Calls" })
      vim.keymap.set("n", "<leader>ck", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Documentation" })
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
  },
  
  -- JSON schema store
  {
    "b0o/schemastore.nvim",
    lazy = true,
  },
  
  -- Improved development with neovim
  {
    "folke/neodev.nvim",
    ft = "lua",
    opts = {},
  },
  
  -- Diagnostics window
  {
    "folke/trouble.nvim",
    cmd = { "TroubleToggle", "Trouble" },
    keys = {
      { "<leader>xx", "<cmd>TroubleToggle document_diagnostics<cr>", desc = "Document Diagnostics" },
      { "<leader>xX", "<cmd>TroubleToggle workspace_diagnostics<cr>", desc = "Workspace Diagnostics" },
      { "<leader>xL", "<cmd>TroubleToggle loclist<cr>", desc = "Location List" },
      { "<leader>xQ", "<cmd>TroubleToggle quickfix<cr>", desc = "Quickfix List" },
      {
        "gR",
        "<cmd>TroubleToggle lsp_references<cr>",
        desc = "LSP References",
      },
    },
    opts = {
      position = "bottom",
      height = 15,
      width = 50,
      icons = true,
      mode = "workspace_diagnostics",
      severity = nil,
      fold_open = "",
      fold_closed = "",
      group = true,
      padding = true,
      action_keys = {
        close = "q",
        cancel = "<esc>",
        refresh = "r",
        jump = { "<cr>", "<tab>" },
        open_split = { "<c-x>" },
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
        next = "j",
      },
      indent_lines = true,
      win_config = { border = "single" },
      auto_jump = {},
      signs = {
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = "",
      },
      use_diagnostic_signs = false,
    },
  },
  
  -- Debugging support
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      -- Creates a debugger UI
      {
        "rcarriga/nvim-dap-ui",
        keys = {
          { "<leader>du", function() require("dapui").toggle() end, desc = "Toggle DAP UI" },
        },
        opts = {},
        config = function(_, opts)
          local dap = require("dap")
          local dapui = require("dapui")
          dapui.setup(opts)
          dap.listeners.after.event_initialized["dapui_config"] = function()
            dapui.open()
          end
          dap.listeners.before.event_terminated["dapui_config"] = function()
            dapui.close()
          end
          dap.listeners.before.event_exited["dapui_config"] = function()
            dapui.close()
          end
        end,
      },
      
      -- Virtual text for the debugger
      {
        "theHamsta/nvim-dap-virtual-text",
        opts = {},
      },
      
      -- Mason integration with DAP
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = { "williamboman/mason.nvim" },
        cmd = { "DapInstall", "DapUninstall" },
        opts = {
          automatic_installation = true,
          ensure_installed = {
            "python",
            "delve",
            "js",
            "codelldb",
          },
          handlers = {},
        },
      },
    },
    keys = {
      { "<leader>dB", function() require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: ")) end, desc = "Breakpoint Condition" },
      { "<leader>db", function() require("dap").toggle_breakpoint() end, desc = "Toggle Breakpoint" },
      { "<leader>dc", function() require("dap").continue() end, desc = "Continue" },
      { "<leader>dC", function() require("dap").run_to_cursor() end, desc = "Run to Cursor" },
      { "<leader>dg", function() require("dap").goto_() end, desc = "Go to Line (no execute)" },
      { "<leader>di", function() require("dap").step_into() end, desc = "Step Into" },
      { "<leader>dj", function() require("dap").down() end, desc = "Down" },
      { "<leader>dk", function() require("dap").up() end, desc = "Up" },
      { "<leader>dl", function() require("dap").run_last() end, desc = "Run Last" },
      { "<leader>do", function() require("dap").step_out() end, desc = "Step Out" },
      { "<leader>dO", function() require("dap").step_over() end, desc = "Step Over" },
      { "<leader>dp", function() require("dap").pause() end, desc = "Pause" },
      { "<leader>dr", function() require("dap").repl.toggle() end, desc = "Toggle REPL" },
      { "<leader>ds", function() require("dap").session() end, desc = "Session" },
      { "<leader>dt", function() require("dap").terminate() end, desc = "Terminate" },
      { "<leader>dw", function() require("dap.ui.widgets").hover() end, desc = "Widgets" },
    },
    config = function()
      local dap = require("dap")
      
      -- Python adapter
      dap.adapters.python = {
        type = "executable",
        command = "python",
        args = { "-m", "debugpy.adapter" },
      }
      
      dap.configurations.python = {
        {
          type = "python",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          pythonPath = function()
            return "python"
          end,
        },
      }
      
      -- JavaScript/TypeScript adapter
      dap.adapters.node2 = {
        type = "executable",
        command = "node",
        args = { vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js" },
      }
      
      dap.configurations.javascript = {
        {
          type = "node2",
          request = "launch",
          name = "Launch file",
          program = "${file}",
          cwd = "${workspaceFolder}",
          sourceMaps = true,
        },
      }
      
      dap.configurations.typescript = dap.configurations.javascript
      
      -- Go adapter
      dap.adapters.delve = {
        type = "server",
        port = "${port}",
        executable = {
          command = "dlv",
          args = { "dap", "-l", "127.0.0.1:${port}" },
        },
      }
      
      dap.configurations.go = {
        {
          type = "delve",
          name = "Debug",
          request = "launch",
          program = "${file}",
        },
      }
    end,
  },
  
  -- Formatter configuration
  {
    "stevearc/conform.nvim",
    lazy = true,
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>fm",
        function()
          require("conform").format({ lsp_fallback = true, async = true })
        end,
        desc = "Format document",
      },
    },
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "isort", "black" },
        javascript = { { "prettierd", "prettier" } },
        typescript = { { "prettierd", "prettier" } },
        rust = { "rustfmt" },
        go = { "gofmt", "goimports" },
        html = { { "prettierd", "prettier" } },
        css = { { "prettierd", "prettier" } },
        json = { { "prettierd", "prettier" } },
        yaml = { { "prettierd", "prettier" } },
        markdown = { { "prettierd", "prettier" } },
      },
      format_on_save = {
        timeout_ms = 500,
        lsp_fallback = true,
      },
    },
  },
  
  -- Linter configuration
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      local lint = require("lint")
      
      lint.linters_by_ft = {
        python = { "flake8", "pylint" },
        javascript = { "eslint" },
        typescript = { "eslint" },
        lua = { "luacheck" },
        sh = { "shellcheck" },
        markdown = { "markdownlint" },
      }
      
      -- Setup autocommands for linting
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter" }, {
        callback = function()
          require("lint").try_lint()
        end,
      })
      
      vim.keymap.set("n", "<leader>l", function() require("lint").try_lint() end, { desc = "Lint file" })
    end,
  },
  
  -- Nvim navic (breadcrumbs)
  {
    "SmiteshP/nvim-navic",
    lazy = true,
    init = function()
      vim.g.navic_silence = true
    end,
    opts = {
      icons = {
        File = " ",
        Module = " ",
        Namespace = " ",
        Package = " ",
        Class = " ",
        Method = " ",
        Property = " ",
        Field = " ",
        Constructor = " ",
        Enum = " ",
        Interface = " ",
        Function = " ",
        Variable = " ",
        Constant = " ",
        String = " ",
        Number = " ",
        Boolean = " ",
        Array = " ",
        Object = " ",
        Key = " ",
        Null = " ",
        EnumMember = " ",
        Struct = " ",
        Event = " ",
        Operator = " ",
        TypeParameter = " ",
      },
      highlight = true,
      separator = " › ",
      depth_limit = 0,
      depth_limit_indicator = "..",
    },
  },
}