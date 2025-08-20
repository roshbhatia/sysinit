local M = {}

M.plugins = {
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require("conform").setup({
        formatters_by_ft = {
          ["*"] = {
            "codespell",
          },
          lua = {
            "stylua",
          },
          nix = {
            "nixfmt",
          },
          markdown = {},
          javascript = {
            "prettier",
          },
          typescript = {
            "prettier",
          },
          javascriptreact = {
            "prettier",
          },
          json = {
            "jq",
          },
          yaml = {
            "yq",
          },
          html = {
            "prettier",
          },
          css = {
            "prettier",
          },
          scss = {
            "prettier",
          },
          sh = {
            "shfmt",
          },
          bash = {
            "shfmt",
            "shellcheck",
          },
          zsh = {
            "shfmt",
          },
          go = {
            "goimports",
            "gofmt",
          },
          rust = {
            "rustfmt",
          },
          terraform = {
            "terraform_fmt",
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
