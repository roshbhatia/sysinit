local M = {}

M.plugins = {
  {
    "sindrets/diffview.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggleFiles", "DiffviewFocusFiles" },
    keys = {
      {
        "<leader>dd",
        function()
          vim.cmd("DiffviewOpen")
        end,
        desc = "DiffviewOpen",
      },
      {
        "<leader>dc",
        function()
          vim.cmd("DiffviewClose")
        end,
        desc = "DiffviewClose",
      },
      {
        "<leader>dh",
        function()
          vim.cmd("DiffviewOpen HEAD")
        end,
        desc = "DiffviewOpen HEAD",
      },
    },
  },
}

return M
