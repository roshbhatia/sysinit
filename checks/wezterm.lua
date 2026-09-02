local lua_root = assert(arg[1], "WezTerm Lua path is required")
local plugin_fixture = assert(arg[2], "plugin fixture path is required")

local switcher_file = assert(io.open(lua_root .. "/sysinit/pkg/ui/switcher.lua", "r"))
local switcher_source = switcher_file:read("*a")
switcher_file:close()
local cli_calls = select(2, switcher_source:gsub('wezterm_bin,%s*"cli"', ""))
local guarded_calls = select(2, switcher_source:gsub('wezterm_bin,%s*"cli",%s*"%-%-no%-auto%-start"', ""))
assert(cli_calls == guarded_calls, "a switcher wezterm cli call can start a headless mux")
assert(
  switcher_source:find("return choices, target_keys .. table.concat(keys) .. remaining_keys", 1, true),
  "the selector alphabet does not place session actions after session rows"
)
assert(
  switcher_source:find("local function tree_selector_controls(filter, target_choices)", 1, true),
  "session actions still prepend the session tree"
)
assert(
  switcher_source:find('name = "toggle_dormant", key = "%.", id = "action:toggle%-dormant"'),
  "dot does not toggle dormant sessions"
)
assert(
  switcher_source:find('name = "close_target", key = "x", id = "action:close%-target"'),
  "x does not open the close picker"
)
assert(not switcher_source:find("session_tree_actions", 1, true), "the selector still depends on an ignored key table")

package.path = table.concat({
  lua_root .. "/?.lua",
  lua_root .. "/?/init.lua",
  package.path,
}, ";")

local handlers = {}
local current_process = "zsh"
local action = setmetatable({}, {
  __index = function(_, name)
    return function(value)
      return { [name] = value == nil and true or value }
    end
  end,
})

local wezterm = {
  action = action,
  action_callback = function(callback)
    return callback
  end,
  enumerate_ssh_hosts = function()
    return {}
  end,
  glob = function()
    return {}
  end,
  gui = {
    default_key_tables = function()
      return {}
    end,
  },
  log_error = function() end,
  log_warn = function() end,
  on = function(name, callback)
    handlers[name] = callback
  end,
  plugin = {
    list = function()
      return {}
    end,
  },
}
package.loaded.wezterm = wezterm

local real_utils = require("sysinit.pkg.utils")
real_utils.get_home_dir = function()
  return "/home/test"
end
real_utils.get_nix_binary = function(name)
  return "/profile/bin/" .. name
end
local nu_args = real_utils.get_nushell_args()
assert(table.concat(nu_args, "\n") == table.concat({
  "/profile/bin/nu",
  "--config",
  "/home/test/.config/nushell/config.nu",
  "--env-config",
  "/home/test/.config/nushell/env.nu",
  "--plugin-config",
  "/home/test/.config/nushell/plugin.msgpackz",
}, "\n"), "WezTerm did not pass every managed Nushell path")

package.loaded["sysinit.pkg.utils"] = {
  get_config_path = function(path)
    return path
  end,
  get_home_dir = function()
    return "/nonexistent"
  end,
  get_nix_binary = function(name)
    return name
  end,
  get_process_name = function()
    return current_process
  end,
  load_json_file = function()
    return {
      plugins = {
        fixture = plugin_fixture,
        missing = plugin_fixture .. "/missing",
      },
    }
  end,
}

local keybindings = require("sysinit.pkg.keybindings")
local key_config = {}
keybindings.setup(key_config)
assert(key_config.disable_default_key_bindings, "default keys remain enabled")
assert(#key_config.keys >= 50, "the key registry lost bindings")

local seen = {}
for _, binding in ipairs(key_config.keys) do
  local chord = binding.mods .. "+" .. binding.key
  assert(not seen[chord], "duplicate WezTerm chord: " .. chord)
  assert(not binding.mods:find("ALT", 1, true), "ALT chord escapes the shared owner: " .. chord)
  seen[chord] = true
end
require("sysinit.pkg.validate").setup(key_config)

local function key_binding(key, mods)
  for _, binding in ipairs(key_config.keys) do
    if binding.key == key and binding.mods == mods then
      return binding
    end
  end
  error("missing WezTerm chord: " .. mods .. "+" .. key)
end

local performed = {}
local pane_vars = { IS_NVIM = "true" }
local window = {
  perform_action = function(_, value)
    performed[#performed + 1] = value
  end,
}
local pane = {
  get_user_vars = function()
    return pane_vars
  end,
}

key_binding("h", "CTRL").action(window, pane)
assert(performed[1].SendKey.key == "h", "CTRL-h did not pass through to Neovim")
key_binding("v", "CTRL").action(window, pane)
assert(performed[2].SplitHorizontal.domain == "CurrentPaneDomain", "CTRL-v did not split from Neovim")
pane_vars = {}
current_process = "slk"
for _, chord in ipairs({
  { "s", "CTRL" },
  { "v", "CTRL" },
  { "f", "CTRL" },
  { "t", "CTRL" },
  { "u", "CTRL" },
  { "d", "CTRL" },
}) do
  local before = #performed
  key_binding(chord[1], chord[2]).action(window, pane)
  assert(performed[before + 1].SendKey.key == chord[1], chord[2] .. "-" .. chord[1] .. " did not reach slk")
end
current_process = "zsh"
key_binding("h", "CTRL").action(window, pane)
assert(performed[9].ActivatePaneDirection == "Left", "CTRL-h did not move from a shell pane")
-- nu is the pane shell now, so a shell list that forgot it would send every
-- readline chord to wezterm instead of to the prompt.
current_process = "nu"
key_binding("u", "CTRL").action(window, pane)
assert(performed[10].SendKey.key == "u", "CTRL-u did not pass through to a nushell pane")
performed[10] = nil
keybindings.locked_mode = true
key_binding("h", "CTRL").action(window, pane)
assert(performed[10].SendKey.mods == "CTRL", "locked mode consumed CTRL-h")
keybindings.locked_mode = false

local event_config = {}
require("sysinit.pkg.events").setup(event_config)
assert(event_config.enable_scroll_bar, "event setup did not enable the scroll bar")

local clipboard
local overrides
local event_action
local event_window = {
  copy_to_clipboard = function(_, value, target)
    clipboard = { value = value, target = target }
  end,
  perform_action = function(_, value)
    event_action = value
  end,
  get_config_overrides = function()
    return { preserved = true }
  end,
  set_config_overrides = function(_, value)
    overrides = value
  end,
}
local alt_screen = false
local event_pane = {
  get_dimensions = function()
    return { scrollback_rows = 100, viewport_rows = 20 }
  end,
  is_alt_screen_active = function()
    return alt_screen
  end,
}

handlers["user-var-changed"](event_window, event_pane, "wez_copy", "copied text")
assert(clipboard.value == "copied text" and clipboard.target == "Clipboard", "wez_copy missed the clipboard")
handlers["user-var-changed"](event_window, event_pane, "SYSINIT_NAV", "left:editor")
assert(event_action.ActivatePaneDirection == "Left", "SYSINIT_NAV did not activate the left pane")
handlers["update-status"](event_window, event_pane)
assert(overrides.preserved and overrides.enable_scroll_bar, "scrollback did not show the scroll bar")
alt_screen = true
handlers["update-status"](event_window, event_pane)
assert(not overrides.enable_scroll_bar, "the alternate screen kept the scroll bar")

local duplicate_config = {
  keys = {
    { mods = "CTRL|SHIFT", key = "x" },
    { mods = "SHIFT|CTRL", key = "x" },
  },
}
assert(not pcall(require("sysinit.pkg.validate").setup, duplicate_config), "reordered duplicate keys passed validation")
local alias_config = {
  keys = {
    { mods = "SUPER", key = "x" },
    { mods = "CMD", key = "x" },
  },
}
assert(not pcall(require("sysinit.pkg.validate").setup, alias_config), "modifier aliases passed validation")

local loader = require("sysinit.pkg.plugin_loader")
local missing = loader.load("missing")
assert(not missing, "a missing plugin loaded")
assert(#wezterm.plugin.list() == 0, "a failed plugin registered as loaded")
local loaded, plugin = loader.load("fixture")
assert(loaded, "the local plugin did not load")
assert(plugin.value == "dependency", "the plugin dependency did not use its local scope")
local loaded_again, cached_plugin = loader.load("fixture")
assert(loaded_again and cached_plugin == plugin, "the plugin loader did not reuse a loaded plugin")
local plugin_list = wezterm.plugin.list()
assert(#plugin_list == 1, "the local plugin did not register")
assert(plugin_list[1].component == "fixture", "the plugin registered under the wrong name")

local calls = {}
for _, name in ipairs({ "core", "events", "keybindings", "ui", "validate" }) do
  package.loaded["sysinit.pkg." .. name] = {
    setup = function(config)
      calls[#calls + 1] = name
      config[name] = true
    end,
  }
end
wezterm.config_builder = function()
  return { built = true }
end
package.loaded["sysinit.pkg.bootstrap"] = nil
local built = require("sysinit.pkg.bootstrap").build()
assert(
  built.built and built.core and built.events and built.keybindings and built.ui and built.validate,
  "bootstrap dropped a module"
)
assert(table.concat(calls, ",") == "core,events,keybindings,ui,validate", "bootstrap changed module order")

package.loaded["sysinit.pkg.ui"] = {
  setup = function()
    error("expected failure")
  end,
}
local degraded = require("sysinit.pkg.bootstrap").build()
assert(
  degraded.core and degraded.events and degraded.keybindings and degraded.validate,
  "one optional failure stopped later composition"
)
assert(handlers["update-status"], "an optional failure registered no report")

package.loaded["sysinit.pkg.ui"] = {
  setup = function(config)
    config.ui = true
  end,
}
package.loaded["sysinit.pkg.validate"] = {
  setup = function()
    error("invalid final config")
  end,
}
local valid, validation_error = pcall(require("sysinit.pkg.bootstrap").build)
assert(not valid, "final validation could not fail the configuration")
assert(tostring(validation_error):find("invalid final config", 1, true), "validation failure lost its cause")

print("WezTerm modules, plugins, and chords passed")
