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
    lazy = false,
    config = function()
      require("smart-splits").setup({
        ignored_buftypes = {
          "terminal",
          "quickfix",
          "prompt",
          "nofile",
        },
        ignored_filetypes = { "NvimTree" },
        default_amount = 3,
        at_edge = function(context)
          if context.mux then
            context.mux.next_pane(context.direction)
          end
        end,
        cursor_follows_swapped_bufs = true,
        float_win_behavior = "mux",
        move_cursor_same_row = false,
        ignored_events = {
          "BufEnter",
          "WinEnter",
        },
        multiplexer_integration = nil,
        disable_multiplexer_nav_when_zoomed = true,
        log_level = "info",
      })
    end,
    keys = function()
      local smart_splits = require("smart-splits")
      return {
        {
          "<C-h>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.move_cursor_left()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to left split",
        },
        {
          "<C-j>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.move_cursor_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to bottom split",
        },
        {
          "<C-k>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.move_cursor_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to top split",
        },
        {
          "<C-l>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.move_cursor_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Move to right split",
        },
        {
          "<C-S-h>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.resize_left()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease width of current split",
        },
        {
          "<C-S-j>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.resize_down()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Decrease height of current split",
        },
        {
          "<C-S-k>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.resize_up()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase height of current split",
        },
        {
          "<C-S-l>",
          function()
            if is_floating_snacks_terminal() then
              return
            end
            smart_splits.resize_right()
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Increase width of current split",
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
          "<C-w>",
          function()
            vim.cmd("close")
          end,
          mode = { "n" },
          desc = "Close current window",
        },
        {
          "<C-a><C-a>",
          function()
            vim.api.nvim_feedkeys(
              vim.api.nvim_replace_termcodes("<C-a>", true, false, true),
              "n",
              true
            )
          end,
          mode = { "n", "i", "v", "t" },
          desc = "Send Ctrl-a to Neovim",
        },
      }
    end,
  },
}

return M
