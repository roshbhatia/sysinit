local M = {}

local function is_floating_snacks_terminal()
  local win_config = vim.api.nvim_win_get_config(0)
  if win_config.relative ~= "" then
    local buf_name = vim.api.nvim_buf_get_name(0)
    if buf_name:match("snacks") then
      return true
    end
  end
  return false
end

M.plugins = {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = true,
    config = function()
      require("smart-splits").setup({
        ignored_buftypes = {
          "terminal",
          "quickfix",
          "prompt",
          "nofile",
        },
        at_edge = "stop",
        cursor_follows_swapped_bufs = true,
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
          desc = "Move to left split",
        },
        {
          "<C-j>",
          function()
            smart_splits.move_cursor_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to bottom split",
        },
        {
          "<C-k>",
          function()
            smart_splits.move_cursor_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to top split",
        },
        {
          "<C-l>",
          function()
            smart_splits.move_cursor_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to right split",
        },
        {
          "<C-S-h>",
          function()
            smart_splits.resize_left()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease width of current split",
        },
        {
          "<C-S-j>",
          function()
            smart_splits.resize_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease height of current split",
        },
        {
          "<C-S-k>",
          function()
            smart_splits.resize_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase height of current split",
        },
        {
          "<C-S-l>",
          function()
            smart_splits.resize_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase width of current split",
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
          "<leader>v",
          function()
            vim.cmd("vsplit")
          end,
          mode = { "n" },
          desc = "Split vertical",
        },
      }
    end,
  },
}

return M
