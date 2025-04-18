-- sysinit.nvim.doc-url="https://raw.githubusercontent.com/karb94/neoscroll.nvim/refs/heads/master/doc/neoscroll.txt"
local M = {}

M.plugins = {
  {
    "karb94/neoscroll.nvim",
    event = "VeryLazy",
    config = function()
      local neoscroll = require('neoscroll')
      
      neoscroll.setup({
        mappings = {
          '<C-u>', '<C-d>',
          '<C-b>', '<C-f>',
          '<C-y>', '<C-e>',
          'zt', 'zz', 'zb',
        },
        hide_cursor = true,          -- Hide cursor while scrolling
        stop_eof = true,             -- Stop at <EOF> when scrolling downwards
        respect_scrolloff = false,   -- Stop scrolling when the cursor reaches the scrolloff margin of the file
        cursor_scrolls_alone = true, -- The cursor will keep on scrolling even if the window cannot scroll further
        easing = 'quadratic',        -- Default easing function (options: linear, quadratic, cubic, quartic, quintic, circular, sine)
        pre_hook = nil,              -- Function to run before the scrolling animation starts
        post_hook = nil,             -- Function to run after the scrolling animation ends
        performance_mode = false,    -- Disable "Performance Mode" on all buffers
      })
      
      local keymap = {
        ["<C-u>"] = function() neoscroll.ctrl_u({ duration = 250 }) end,
        ["<C-d>"] = function() neoscroll.ctrl_d({ duration = 250 }) end,
        ["<C-b>"] = function() neoscroll.ctrl_b({ duration = 350 }) end,
        ["<C-f>"] = function() neoscroll.ctrl_f({ duration = 350 }) end,
        ["<C-y>"] = function() neoscroll.scroll(-0.1, { move_cursor = false, duration = 100 }) end,
        ["<C-e>"] = function() neoscroll.scroll(0.1, { move_cursor = false, duration = 100 }) end,
        ["zt"]    = function() neoscroll.zt({ half_win_duration = 200 }) end,
        ["zz"]    = function() neoscroll.zz({ half_win_duration = 200 }) end,
        ["zb"]    = function() neoscroll.zb({ half_win_duration = 200 }) end,
      }
      
      local modes = { 'n', 'v', 'x' }
      for key, func in pairs(keymap) do
        vim.keymap.set(modes, key, func, { silent = true })
      end
    end
  }
}

function M.setup()
  local status, wk = pcall(require, "which-key")
  if status then
    wk.add({
      { "<C-u>", desc = "Scroll half-page up (smooth)" },
      { "<C-d>", desc = "Scroll half-page down (smooth)" },
      { "<C-b>", desc = "Scroll page up (smooth)" },
      { "<C-f>", desc = "Scroll page down (smooth)" },
      { "<C-y>", desc = "Scroll up slightly (smooth)" },
      { "<C-e>", desc = "Scroll down slightly (smooth)" },
      { "zt", desc = "Scroll to top (smooth)" },
      { "zz", desc = "Scroll to center (smooth)" },
      { "zb", desc = "Scroll to bottom (smooth)" },
    })
  end
end

return M
