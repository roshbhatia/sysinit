-- Resurrect.wezterm plugin integration for workspace persistence
-- Provides ability to save and restore pane layouts, working directories, and running processes
local wezterm = require("wezterm")

local M = {}

function M.setup(config)
  -- Load the resurrect plugin
  local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

  -- Configure resurrect plugin
  resurrect.periodic_save({
    interval_seconds = 300, -- Save every 5 minutes
    enable = true,
  })

  -- Set up workspace persistence directory
  resurrect.set_workspace_dir(wezterm.home_dir .. "/.local/share/wezterm/resurrect")

  -- Keybindings for manual workspace management
  -- These will work alongside the automatic periodic saves
  local resurrect_keys = {
    {
      key = "s",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, _pane)
        local state = resurrect.workspace_state.get_workspace_state()
        resurrect.save_state(state)
        win:toast_notification("wezterm", "Workspace saved!", nil, 4000)
      end),
    },
    {
      key = "r",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, _pane)
        resurrect.workspace_state.restore_workspace(resurrect.load_state(), {
          relative = true,
          restore_text = true,
          on_pane_restore = resurrect.tab_state.default_on_pane_restore,
        })
        win:toast_notification("wezterm", "Workspace restored!", nil, 4000)
      end),
    },
    {
      key = "l",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        resurrect.fuzzy_load(win, pane, function(id)
          local state = resurrect.load_state(id)
          resurrect.workspace_state.restore_workspace(state, {
            relative = true,
            restore_text = true,
            on_pane_restore = resurrect.tab_state.default_on_pane_restore,
          })
        end)
      end),
    },
    {
      key = "d",
      mods = "LEADER",
      action = wezterm.action_callback(function(win, pane)
        resurrect.delete_state(resurrect.fuzzy_load(win, pane))
      end),
    },
  }

  -- Add resurrect keybindings to config
  for _, key in ipairs(resurrect_keys) do
    table.insert(config.keys, key)
  end
end

return M
