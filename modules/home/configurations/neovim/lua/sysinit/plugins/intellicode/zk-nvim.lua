local M = {}

M.plugins = {
  {
    "zk-org/zk-nvim",
    event = "VeryLazy",
    config = function()
      require("zk").setup({
        picker = "telescope",
        lsp = {
          config = {
            name = "zk",
            cmd = {
              "zk",
              "lsp",
            },
            filetypes = {
              "markdown",
            },
          },
          auto_attach = {
            enabled = true,
          },
        },
      })
    end,
  },
}

return M
