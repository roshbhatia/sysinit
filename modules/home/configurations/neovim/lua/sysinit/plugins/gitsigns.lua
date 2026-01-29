---@diagnostic disable: param-type-mismatch

return {
  {
    "lewis6991/gitsigns.nvim",
    event = "VeryLazy",
    config = function()
      require("gitsigns").setup({
        preview_config = {
          style = "minimal",
          relative = "cursor",
          border = "rounded",
          row = 0,
          col = 1,
        },
        numhl = false,
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
          "<leader>ghs",
          function()
            require("gitsigns").stage_hunk()
          end,
          desc = "Stage hunk",
          mode = "n",
        },
        {
          "<leader>ghs",
          function()
            require("gitsigns").stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Stage hunk",
          mode = "v",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk()
          end,
          desc = "Reset hunk",
          mode = "n",
        },
        {
          "<leader>ghr",
          function()
            require("gitsigns").reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
          end,
          desc = "Reset hunk",
          mode = "v",
        },
        {
          "<leader>gbs",
          function()
            require("gitsigns").stage_buffer()
          end,
          desc = "Stage buffer",
          mode = "n",
        },
        {
          "<leader>gbr",
          function()
            require("gitsigns").reset_buffer()
          end,
          desc = "Reset buffer",
          mode = "n",
        },
        {
          "<leader>ghu",
          function()
            require("gitsigns").undo_stage_hunk()
          end,
          desc = "Undo stage hunk",
          mode = "n",
        },
        {
          "<leader>ghp",
          function()
            require("gitsigns").preview_hunk_inline()
          end,
          desc = "Preview hunk",
          mode = "n",
        },
        {
          "<leader>ghq",
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
