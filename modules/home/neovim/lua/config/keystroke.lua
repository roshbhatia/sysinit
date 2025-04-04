-- Keystroke display configuration
local M = {}

function M.setup()
  -- Check if we can load the noice plugin
  local has_noice, noice = pcall(require, "noice")
  if not has_noice then
    return
  end
  
  -- Configure noice for keystroke display
  noice.setup({
    cmdline = {
      view = "cmdline",
      format = {
        cmdline = { icon = "❯" },
        search_down = { icon = "🔍⌄" },
        search_up = { icon = "🔍⌃" },
        filter = { icon = "$" },
        lua = { icon = "☾" },
        help = { icon = "?" },
      },
    },
    views = {
      mini = {
        win_options = {
          winblend = 0,
        },
      },
    },
    routes = {
      -- Show macro recording messages in the cmdline area
      {
        filter = {
          event = "msg_showmode",
        },
        view = "cmdline",
      },
    },
    -- Show key presses
    messages = {
      view = "mini",
      view_warn = "mini",
      view_error = "mini",
      view_history = "messages",
    },
    -- Enable keystroke display
    notify = {
      enabled = true,
      view = "mini",
    },
    -- Show keys in command line
    keystrokes = {
      enabled = true,
      view = "cmdline",
      clear_on_escape = true,
      format = {
        width = 25,
        spacing = 4,
        separator = "→",
      },
    },
  })
end

return M