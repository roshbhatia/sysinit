return {
  {
    "stevearc/conform.nvim",
    event = "VeryLazy",
    opts = {
      formatters_by_ft = {
        cue = { "cue_fmt" },
        lua = { "stylua" },
        nix = { "nixfmt" },
        javascript = { "prettier" },
        typescript = { "prettier" },
        javascriptreact = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "jq" },
        yaml = { "yq" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        zsh = { "shfmt" },
        go = { "goimports", "gofmt" },
        rust = { "rustfmt" },
        terraform = { "terraform_fmt" },
      },
      default_format_opts = {
        lsp_format = "fallback",
      },
      notify_on_error = false,
      format_after_save = function(bufnr)
        if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
          return
        end
        local ok, stats = pcall(vim.uv.fs_stat, vim.api.nvim_buf_get_name(bufnr))
        if ok and stats and stats.size and stats.size > 1024 * 1024 then
          return
        end
        return { lsp_format = "fallback" }
      end,
    },
    init = function()
      vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

      -- Initialize session variables for format control
      vim.g.disable_autoformat = false
      vim.b.disable_autoformat = false

      -- Run statix fix before nixfmt for Nix files
      vim.api.nvim_create_autocmd("BufWritePre", {
        desc = "Run statix fix before formatting Nix files",
        pattern = "*.nix",
        group = vim.api.nvim_create_augroup("StatixFormat", { clear = true }),
        callback = function(ev)
          local conform_opts = { bufnr = ev.buf, lsp_format = "fallback", timeout_ms = 2000 }
          local filename = vim.api.nvim_buf_get_name(ev.buf)

          -- Run statix fix
          local result = vim.fn.system("statix fix " .. vim.fn.shellescape(filename))
          if vim.v.shell_error ~= 0 then
            vim.notify("statix fix failed: " .. result, vim.log.levels.WARN)
          end

          -- Reload buffer if file was modified by statix
          vim.cmd("edit!")

          -- Then run conform
          require("conform").format(conform_opts)
        end,
      })

      -- Run goimports before gofmt for Go files (via LSP)
      vim.api.nvim_create_autocmd("BufWritePre", {
        desc = "Run goimports before formatting Go files",
        pattern = "*.go",
        group = vim.api.nvim_create_augroup("GoImportsFormat", { clear = true }),
        callback = function(ev)
          local conform_opts = { bufnr = ev.buf, lsp_format = "fallback", timeout_ms = 2000 }
          local client = vim.lsp.get_clients({ name = "gopls", bufnr = ev.buf })[1]

          if not client then
            require("conform").format(conform_opts)
            return
          end

          local request_result = client:request_sync("workspace/executeCommand", {
            command = "source.organizeImports",
            arguments = { vim.api.nvim_buf_get_name(ev.buf) },
          })

          if request_result and request_result.err then
            vim.notify(request_result.err.message, vim.log.levels.WARN)
          end

          require("conform").format(conform_opts)
        end,
      })

      vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
          local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
          range = {
            start = { args.line1, 0 },
            ["end"] = { args.line2, end_line:len() },
          }
        end
        require("conform").format({ async = true, lsp_format = "fallback", range = range })
      end, { range = true, desc = "Format buffer or range" })

      vim.api.nvim_create_user_command("FormatDisable", function()
        vim.g.disable_autoformat = true
      end, { desc = "Disable autoformat-on-save globally" })

      vim.api.nvim_create_user_command("FormatEnable", function()
        vim.g.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save globally" })

      vim.api.nvim_create_user_command("FormatBufDisable", function()
        vim.b.disable_autoformat = true
      end, { desc = "Disable autoformat-on-save for buffer" })

      vim.api.nvim_create_user_command("FormatBufEnable", function()
        vim.b.disable_autoformat = false
      end, { desc = "Re-enable autoformat-on-save for buffer" })

      vim.api.nvim_create_user_command("FormatStatus", function()
        local global = vim.g.disable_autoformat and "disabled" or "enabled"
        local buffer = vim.b.disable_autoformat and "disabled" or "enabled"
        vim.notify(string.format("Autoformat: global=%s, buffer=%s", global, buffer), vim.log.levels.INFO)
      end, { desc = "Show autoformat status" })
    end,
  },
}
