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
        yaml = {},
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
