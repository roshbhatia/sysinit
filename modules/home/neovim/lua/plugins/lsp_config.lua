return {
  -- Enhanced LSP configuration with ShellCheck support
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "nvim-telescope/telescope.nvim",
    },
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      -- Setup neodev for better Lua development
      require("neodev").setup({})
      
      -- Setup mason first for package management
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
      
      -- Configure mason-lspconfig
      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "bashls",    -- Bash language server
          "pyright",   -- Python
          "jsonls",    -- JSON
          "yamlls",    -- YAML
          "tsserver",  -- TypeScript/JavaScript
          "html",      -- HTML
          "cssls",     -- CSS
        },
        automatic_installation = true,
      })
      
      -- Add visual indicator for diagnostics with icons
      local signs = {
        { name = "DiagnosticSignError", text = "󰅚" },
        { name = "DiagnosticSignWarn", text = "󰀪" },
        { name = "DiagnosticSignHint", text = "󰌶" },
        { name = "DiagnosticSignInfo", text = "󰋽" },
      }
      
      for _, sign in ipairs(signs) do
        vim.fn.sign_define(sign.name, { texthl = sign.name, text = sign.text, numhl = "" })
      end
      
      -- Configure diagnostics display
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●", -- Could be '■', '▎', 'x'
          source = "if_many", -- Only show source if multiple diagnostics
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
      
      -- Set up LSP keymaps when a language server attaches
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('UserLspConfig', {}),
        callback = function(ev)
          local bufnr = ev.buf
          local client = vim.lsp.get_client_by_id(ev.data.client_id)
          
          -- Enable completion triggered by <c-x><c-o>
          vim.bo[bufnr].omnifunc = 'v:lua.vim.lsp.omnifunc'
          
          -- Buffer local mappings
          local opts = { buffer = bufnr, noremap = true, silent = true }
          vim.keymap.set('n', 'gd', vim.lsp.buf.definition, { buffer = bufnr, desc = "󰞙 Go to definition" })
          vim.keymap.set('n', 'gr', vim.lsp.buf.references, { buffer = bufnr, desc = "󰮍 Find references" })
          vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, { buffer = bufnr, desc = "󰡱 Go to implementation" })
          vim.keymap.set('n', 'K', vim.lsp.buf.hover, { buffer = bufnr, desc = "󰖨 Show hover docs" })
          vim.keymap.set('n', '<leader>cr', vim.lsp.buf.rename, { buffer = bufnr, desc = "󰛿 Rename symbol" })
          vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, { buffer = bufnr, desc = "󰛨 Code actions" })
          vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format({ async = true }) end, { buffer = bufnr, desc = "󰉶 Format document" })
          vim.keymap.set('n', '<leader>cd', vim.diagnostic.open_float, { buffer = bufnr, desc = "󱌲 Line diagnostics" })
          vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { buffer = bufnr, desc = "󰝤 Previous diagnostic" })
          vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { buffer = bufnr, desc = "󰝦 Next diagnostic" })
          
          -- Add outline support
          if client.server_capabilities.documentSymbolProvider then
            require("which-key").register({
              ["<leader>cs"] = { "<cmd>Telescope lsp_document_symbols<CR>", "󰛩 Document symbols" },
            }, { buffer = bufnr })
          end
        end,
      })
      
      -- Configure LSP servers
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp-nvim-lsp').default_capabilities()
      
      -- Lua Language Server
      lspconfig.lua_ls.setup({
        capabilities = capabilities,
        settings = {
          Lua = {
            diagnostics = {
              globals = { 'vim' }
            },
            workspace = {
              checkThirdParty = false,
              library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = {
              enable = false,
            },
          }
        }
      })
      
      -- Bash Language Server with ShellCheck integration
      lspconfig.bashls.setup({
        capabilities = capabilities,
        settings = {
          bashIde = {
            shellcheckPath = vim.fn.exepath("shellcheck"),
            enableSourceErrorDiagnostics = true,
          }
        },
        filetypes = { "sh", "bash", "zsh" },
      })
      
      -- Make sure shellcheck is properly integrated
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "sh", "bash", "zsh" },
        callback = function()
          -- Check if shellcheck is installed
          if vim.fn.executable("shellcheck") == 1 then
            -- Add efm configuration for shellcheck if available
            if vim.fn.executable("efm-langserver") == 1 then
              local shellcheck_config = {
                lintCommand = "shellcheck -f gcc -x ${INPUT}",
                lintFormats = { "%f:%l:%c: %trror: %m", "%f:%l:%c: %tarning: %m", "%f:%l:%c: %tote: %m" },
                lintSource = "shellcheck",
              }
              
              -- Try to set up efm if available
              pcall(function()
                lspconfig.efm.setup({
                  init_options = { documentFormatting = true },
                  settings = {
                    languages = {
                      sh = { shellcheck_config },
                      bash = { shellcheck_config },
                      zsh = { shellcheck_config },
                    }
                  },
                  filetypes = { "sh", "bash", "zsh" },
                })
              end)
            end
            
            -- Set quickfix keyboard shortcut to execute shellcheck directly
            vim.keymap.set("n", "<leader>cs", function()
              local filename = vim.fn.expand("%:p")
              vim.fn.system("shellcheck -f gcc " .. filename .. " > /tmp/shellcheck_results.txt")
              if vim.v.shell_error ~= 0 then
                vim.cmd("cfile /tmp/shellcheck_results.txt")
                vim.cmd("copen")
              else
                vim.cmd("cclose")
                print("No shellcheck errors found!")
              end
            end, { buffer = true, desc = "󰿘 Run ShellCheck" })
          else
            print("ShellCheck not found. Install it for better shell script linting.")
            -- Offer to install shellcheck via Mason
            if vim.fn.executable("mason") == 1 then
              print("You can install ShellCheck by running :MasonInstall shellcheck")
            end
          end
        end
      })
      
      -- Add command to fix shellcheck errors
      vim.api.nvim_create_user_command("ShellCheckFix", function()
        local filename = vim.fn.expand("%:p")
        if vim.fn.executable("shellcheck") == 1 and vim.fn.executable("shellfix") == 1 then
          vim.fn.system("shellfix " .. filename)
          print("Applied shellfix to current file")
          vim.cmd("edit!") -- Reload the file
        else
          print("Requires shellcheck and shellfix to be installed")
        end
      end, {})
    end,
  },
  
  -- Trouble for better diagnostics UI
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