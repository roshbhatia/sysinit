-- A wezterm user var rides the tty as an OSC 1337 escape, so it crosses ssh.
-- Everything else wezterm could use to identify this pane does not: the
-- foreground process name it sees is the local `ssh`, and `wezterm cli` does not
-- exist on the remote.
--
-- Writing to stderr rather than stdout is smart-splits' own choice in
-- autoload/smart_splits.vim, kept here so both writers behave the same.
local nav_seq = 0

local function ask_wezterm_to_move(direction)
  -- wezterm fires `user-var-changed` only when the VALUE changes, so a bare
  -- direction would move once and then go dead on the second identical press.
  nav_seq = nav_seq + 1
  local payload = vim.base64.encode(direction .. ":" .. nav_seq)
  vim.fn.chansend(vim.v.stderr, ("\27]1337;SetUserVar=SYSINIT_NAV=%s\7"):format(payload))
end

return {
  {
    "mrjones2014/smart-splits.nvim",
    event = "VeryLazy",
    config = function()
      local ft = require("utils.filetypes")
      require("smart-splits").setup({
        cursor_follows_swapped_bufs = true,
        -- Reached only after smart-splits has already failed to move the
        -- multiplexer itself, which is the remote case: over ssh its wezterm
        -- backend shells out to `wezterm cli` and TERM_PROGRAM is not forwarded,
        -- so it neither detects wezterm nor can drive it. Locally the mux path
        -- wins first and this never runs, except at the outermost wezterm pane,
        -- where asking to move simply finds no pane and nothing happens.
        --
        -- This replaces `at_edge = "stop"`, which is what left the cursor stuck
        -- in the rightmost window of a remote nvim with a wezterm pane beside it.
        at_edge = function(ctx)
          ask_wezterm_to_move(ctx.direction)
        end,
        default_amount = 3,
        ignored_filetypes = ft.sidebar_filetypes,
        ignored_buftypes = ft.utility_buftypes,
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
          desc = "Move to right pane",
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
      }
    end,
  },
}
