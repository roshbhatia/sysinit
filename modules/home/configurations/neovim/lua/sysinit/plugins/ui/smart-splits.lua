local M = {}

M.plugins = {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("smart-splits").setup({
        ignored_buftypes = {
          "terminal",
        },
        cursor_follows_swapped_bufs = true,
        float_win_behavior = "mux",
        multiplexer_integration = "wezterm",
        at_edge = "stop",
      })
    end,
    keys = function()
      local smart_splits = require("smart-splits")
      return {
        {
          "<C-h>",
          function()
            smart_splits.move_cursor_left()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to left pane",
        },
        {
          "<C-j>",
          function()
            smart_splits.move_cursor_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to bottom pane",
        },
        {
          "<C-k>",
          function()
            smart_splits.move_cursor_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to top pane",
        },
        {
          "<C-l>",
          function()
            smart_splits.move_cursor_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move right pane",
        },
        {
          "<C-S-h>",
          function()
            smart_splits.resize_left()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease pane width",
        },
        {
          "<C-S-j>",
          function()
            smart_splits.resize_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease pane height",
        },
        {
          "<C-S-k>",
          function()
            smart_splits.resize_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase pane height",
        },
        {
          "<C-S-l>",
          function()
            smart_splits.resize_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase pane width",
        },
        {
          "<leader>v",
          function()
            vim.cmd("vsplit")
          end,
          mode = { "n" },
          desc = "Split pane vertically",
        },
        {
          "<leader>s",
          function()
            vim.cmd("split")
          end,
          mode = { "n" },
          desc = "Split pane horizontally",
        },
        {
          "<C-w>",
          function()
            vim.cmd("xit")
          end,
          mode = { "n" },
          desc = "Close pane",
        },
      }
    end,
  },
}

return M
