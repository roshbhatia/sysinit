local M = {}

M.plugins = {
  {
    "dnlhc/glance.nvim",
    cmd = "Glance",
    event = {
      "LSPAttach",
    },
    opts = {
      winbar = {
        enable = true,
      },
      border = {
        enable = true,
      },
      theme = {
        mode = "darken",
      },
      folds = {
        folded = false,
      },
      use_trouble_qf = true,
    },
    keys = function()
      return {
        {
          "<leader>cd",
          function() vim.cmd("Glance definitions") end,
          desc = "Peek at definition",
        },
        {
          "<leader>ci",
          "<CMD>Glance implementations<CR>",
          desc = "Peek at implementations",
        },
        {
          "<leader>cu",
          function() vim.cmd("Glance references") end,
          desc = "Peek at references",
        },
      }
    end,
  },
}

return M
