local M = {}

M.plugins = {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        word_diff = true,
        preview_config = {
          style = "minimal",
          relative = "cursor",
          border = "rounded",
          row = 0,
          col = 1,
        },
      })
    end,
    keys = function()
      return {
        {
          "]c",
          function()
            if vim.wo.diff then
              vim.cmd.normal({ "]c", bang = true })
            else
              require("gitsigns").nav_hunk("next")
            end
          end,
          desc = "Next hunk",
          mode = "n",
        },
        {
          "[c",
          function()
            if vim.wo.diff then
              vim.cmd.normal({ "[c", bang = true })
            else
              require("gitsigns").nav_hunk("prev")
            end
          end,
          desc = "Previous hunk",
          mode = "n",
        },
        {
          "<leader>gs",
          function()
            require("gitsigns").stage_hunk()
          end,
          desc = "Stage hunk",
          mode = "n",
        },
        {
          "<leader>gs",
          function()
            require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Stage hunk",
          mode = "v",
        },
        {
          "<leader>gr",
          function()
            require("gitsigns").reset_hunk()
          end,
          desc = "Rest hunk",
          mode = "n",
        },
        {
          "<leader>gr",
          function()
            require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Reset hunk",
          mode = "v",
        },
        {
          "<leader>gS",
          function()
            require("gitsigns").stage_buffer()
          end,
          desc = "Stage buffer",
          mode = "n",
        },
        {
          "<leader>gR",
          function()
            require("gitsigns").reset_buffer()
          end,
          desc = "Reset buffer",
          mode = "n",
        },
        {
          "<leader>gU",
          function()
            require("gitsigns").undo_stage_hunk()
          end,
          desc = "Undo stage hunk",
          mode = "n",
        },
        {
          "<leader>gp",
          function()
            require("gitsigns").preview_hunk()
          end,
          desc = "Preview hunk",
          mode = "n",
        },
        {
          "<leader>gq",
          function()
            require("gitsigns").setqflist("all")
          end,
          desc = "Quickfix hunks",
          mode = "n",
        },
      }
    end,
  },
}

return M
