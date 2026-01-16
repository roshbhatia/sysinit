local M = {}

M.plugins = {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      require("smart-splits").setup({
        cursor_follows_swapped_bufs = true,
        float_win_behavior = "mux",
        at_edge = "stop",
      })
    end,
    keys = function()
      local smart_splits = require("smart-splits")
      return {
        {
          "<C-a>h",
          function()
            smart_splits.move_cursor_left()
          end,
          mode = { "n", "v" },
          desc = "Move left",
        },
        {
          "<C-a>j",
          function()
            smart_splits.move_cursor_down()
          end,
          mode = { "n", "v" },
          desc = "Move down",
        },
        {
          "<C-a>k",
          function()
            smart_splits.move_cursor_up()
          end,
          mode = { "n", "v" },
          desc = "Move up",
        },
        {
          "<C-a>l",
          function()
            smart_splits.move_cursor_right()
          end,
          mode = { "n", "v" },
          desc = "Move right",
        },
        {
          "<C-a>H",
          function()
            smart_splits.resize_left()
          end,
          mode = { "n" },
          desc = "Resize left",
        },
        {
          "<C-a>J",
          function()
            smart_splits.resize_down()
          end,
          mode = { "n" },
          desc = "Resize down",
        },
        {
          "<C-a>K",
          function()
            smart_splits.resize_up()
          end,
          mode = { "n" },
          desc = "Resize up",
        },
        {
          "<C-a>L",
          function()
            smart_splits.resize_right()
          end,
          mode = { "n" },
          desc = "Resize right",
        },
        {
          "<leader>v",
          function()
            vim.cmd("vsplit")
          end,
          mode = { "n" },
          desc = "Split vertical",
        },
        {
          "<leader>s",
          function()
            vim.cmd("split")
          end,
          mode = { "n" },
          desc = "Split horizontal",
        },
        {
          "<leader>x",
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
