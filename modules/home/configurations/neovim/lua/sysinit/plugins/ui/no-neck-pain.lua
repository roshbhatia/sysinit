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
          "<leader>ec",
          function()
            vim.cmd("NoNeckPain")
          end,
          desc = "Toggle centering",
          mode = "n",
        },
        {
          "<leader>ei",
          function()
            vim.cmd("NoNeckPainWidthUp")
          end,
          desc = "Increase centered width",
          mode = "n",
        },
        {
          "<leader>ed",
          function()
            vim.cmd("NoNeckPainWidthDown")
          end,
          desc = "Decrease centered width",
          mode = "n",
        },
      }
    end,
  },
}

return M
