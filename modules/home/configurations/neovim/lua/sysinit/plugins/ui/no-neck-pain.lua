local M = {}

M.plugins = {
  {
    "shortcuts/no-neck-pain.nvim",
    version = "*",
    config = function()
      require("no-neck-pain").setup({
        width = 200,
        noremap = true,
        colors = {
          blend = -0.2,
        },
      })
    end,
    keys = function()
      return {
        {
          "<leader>[]",
          function()
            vim.cmd("NoNeckPain")
          end,
          desc = "Toggle centering",
          mode = "n",
        },
        {
          "<leader>][",
          function()
            vim.cmd("NoNeckPain")
          end,
          desc = "Toggle centering",
          mode = "n",
        },
      }
    end,
  },
}

return M
