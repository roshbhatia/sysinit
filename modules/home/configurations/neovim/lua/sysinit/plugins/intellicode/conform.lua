local M = {}
M.plugins = {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          lua = { "stylua" },
          markdown = {},
          javascript = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          typescript = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          javascriptreact = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          typescriptreact = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          json = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          yaml = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          html = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          css = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          scss = {
            "prettierd",
            "prettier",
            stop_after_first = true,
          },
          sh = { "shfmt" },
          bash = { "shfmt" },
          zsh = { "shfmt" },
          nix = { "alejandra" },
          go = { "goimports" },
          rust = { "rustfmt" },
          zig = { "zigfmt" },
          terraform = { "terraform_fmt" },
          java = { "google-java-format" },
        },
        formatters = {
          shfmt = {
            prepend_args = { "-i", "2" },
          },
          alejandra = {
            command = "alejandra",
          },
          zigfmt = {
            command = "zig",
            args = { "fmt", "--stdin" },
          },
          terraform_fmt = {
            command = "terraform",
            args = { "fmt", "-" },
          },
        },
        notify_on_error = false,
        format_after_save = function(bufnr)
          if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
            return
          end
          local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(bufnr))
          if ok and stats and stats.size and stats.size > 1024 * 1024 then
            return
          end
          return {
            lsp_format = "fallback",
          }
        end,
      })
    end,
  },
}
return M

