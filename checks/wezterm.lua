local lua_root = assert(arg[1], "WezTerm Lua path is required")
local plugin_fixture = assert(arg[2], "plugin fixture path is required")

local switcher_file = assert(io.open(lua_root .. "/sysinit/pkg/ui/switcher.lua", "r"))
local switcher_source = switcher_file:read("*a")
switcher_file:close()
local ui_file = assert(io.open(lua_root .. "/sysinit/pkg/ui.lua", "r"))
local ui_source = ui_file:read("*a")
ui_file:close()
assert(not ui_source:find("config.animation_fps", 1, true), "WezTerm overrides the default animation frame rate")
assert(not ui_source:find("config.max_fps", 1, true), "WezTerm overrides the default maximum frame rate")
local interval_assignments = select(2, ui_source:gsub("config%.status_update_interval%s*=", ""))
local final_plugin = assert(ui_source:find("ui_switcher.setup", 1, true), "the final UI plugin setup is missing")
local final_interval = assert(
  ui_source:find("config.status_update_interval = 1000", 1, true),
  "the effective status interval is not one second"
)
assert(interval_assignments == 1, "a plugin can still inherit an earlier status interval")
assert(final_interval > final_plugin, "the status interval is set before plugin application")
local cli_calls = select(2, switcher_source:gsub('wezterm_bin,%s*"cli"', ""))
local guarded_calls = select(2, switcher_source:gsub('wezterm_bin,%s*"cli",%s*"%-%-no%-auto%-start"', ""))
assert(cli_calls == guarded_calls, "a switcher wezterm cli call can start a headless mux")
assert(not switcher_source:find('id = "action:', 1, true), "a picker action is still rendered as a selectable row")
assert(switcher_source:find('brief = "Open directory group"', 1, true), "directory groups have no separate picker")
assert(
  switcher_source:find('brief = "Session: close target"', 1, true),
  "session targets have no separate close picker"
)

package.path = table.concat({
  lua_root .. "/?.lua",
  lua_root .. "/?/init.lua",
  package.path,
}, ";")

local handlers = {}
local current_process = "zsh"
-- Each test swaps these; the wezterm stub itself is assigned once.
local child_process = function(_args)
  return false, "", "no child process stub"
end
local json_parse = function(text)
  error("no json_parse stub for: " .. tostring(text))
end
local logged = {}
-- The mux the tree walks and the panes it can activate; each test sets them.
local mux_windows = {}
local mux_panes = {}
local action = setmetatable({}, {
  __index = function(_, name)
    return function(value)
      return { [name] = value == nil and true or value }
    end
  end,
})

local wezterm = {
  GLOBAL = {},
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
  log_error = function(message)
    logged[#logged + 1] = message
  end,
  log_warn = function() end,
  mux = {
    all_windows = function()
      return mux_windows
    end,
    get_pane = function(id)
      return mux_panes[id]
    end,
  },
  -- The glyph names the fixtures carry, so a resolved glyph is one letter.
  nerdfonts = { cod_briefcase = "B", md_server = "S", md_sleep = "D" },
  run_child_process = function(args)
    return child_process(args)
  end,
  json_parse = function(text)
    return json_parse(text)
  end,
  on = function(name, callback)
    handlers[name] = callback
  end,
  time = {
    call_after = function(_, callback)
      callback()
    end,
  },
  plugin = {
    list = function()
      return {}
    end,
  },
  split_by_newlines = function(value)
    local lines = {}
    for line in value:gmatch("([^\n]*)\n?") do
      if line ~= "" then
        lines[#lines + 1] = line
      end
    end
    return lines
  end,
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
local expected_config_root = os.getenv("XDG_CONFIG_HOME") or "/home/test/.config"
assert(table.concat(nu_args, "\n") == table.concat({
  "/profile/bin/nu",
  "--config",
  expected_config_root .. "/nushell/config.nu",
  "--env-config",
  expected_config_root .. "/nushell/env.nu",
  "--plugin-config",
  expected_config_root .. "/nushell/plugin.msgpackz",
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
  load_json_file = function(path)
    return {
      plugins = {
        fixture = plugin_fixture,
        missing = plugin_fixture .. "/missing",
      },
      directories = { list = { "list-directories" }, open = { "open-directory" } },
      cwd_aliases = { sy = "/state/seshy/sessions" },
      passthrough_procs = { "zmx", "caffeinate" },
    }
  end,
  state_path = function(_, fallback)
    return "/state/" .. fallback
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
key_binding("s", "CTRL|SHIFT").action(window, pane)
assert(performed[3].SplitPane.direction == "Down", "CTRL-SHIFT-s did not create a top-level down split")
key_binding("v", "CTRL|SHIFT").action(window, pane)
assert(performed[4].SplitPane.direction == "Right", "CTRL-SHIFT-v did not create a top-level right split")
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
assert(performed[11].ActivatePaneDirection == "Left", "CTRL-h did not move from a shell pane")
-- nu is the pane shell now, so a shell list that forgot it would send every
-- readline chord to wezterm instead of to the prompt.
current_process = "nu"
key_binding("u", "CTRL").action(window, pane)
assert(performed[12].SendKey.key == "u", "CTRL-u did not pass through to a nushell pane")
performed[12] = nil
keybindings.locked_mode = true
key_binding("h", "CTRL").action(window, pane)
assert(performed[12].SendKey.mods == "CTRL", "locked mode consumed CTRL-h")
keybindings.locked_mode = false

current_process = "traces"
key_binding("f", "CTRL").action(window, pane)
assert(performed[13].SendKey.key == "f", "CTRL-f did not reach Traces")
key_binding("w", "CTRL").action(window, pane)
assert(performed[14].SendKey.key == "w", "CTRL-w did not reach Traces")
current_process = "orc"
key_binding("f", "CTRL").action(window, pane)
assert(performed[15].SendKey.key == "f", "CTRL-f did not reach Orc")
key_binding("w", "CTRL").action(window, pane)
assert(performed[16].SendKey.key == "w", "CTRL-w did not reach Orc")
current_process = "slk"
for _, key in ipairs({ "n", "w" }) do
  local before = #performed
  key_binding(key, "CTRL").action(window, pane)
  assert(performed[before + 1].SendKey.key == key, "CTRL-" .. key .. " did not reach slk")
end
current_process = "traces"
local before = #performed
key_binding("n", "CTRL").action(window, pane)
assert(performed[before + 1].SendKey.key == "n", "CTRL-n did not reach the Traces command picker")

local selector = require("sysinit.pkg.ui.switcher").session_selector_options({
  { id = "ws:newest", label = "newest" },
  { id = "ws:older", label = "older" },
}, "open")
assert(#selector.choices == 2, "the session picker injected a non-session row")
assert(selector.choices[1].id == "ws:newest", "the session picker changed recency order")
assert(not selector.alphabet:find("j", 1, true), "j selects a row instead of moving down")
assert(not selector.alphabet:find("k", 1, true), "k selects a row instead of moving up")
assert(not selector.alphabet:find("x", 1, true), "x selects a row after the close action moved out of the picker")
assert(not selector.alphabet:find("/", 1, true), "/ cannot enter the built-in filter")
assert(
  require("sysinit.pkg.ui.switcher").session_tree_description()
    == "  j/k nav  Enter open  . directory  x close  / filter  Esc quit",
  "session tree help diverged from its action metadata"
)

local session_config = {}
local switcher = require("sysinit.pkg.ui.switcher")
switcher.setup(session_config, { apply_to_config = function() end }, {
  sessions = function()
    return {}, {}
  end,
  tree = function()
    return { workspaces = {}, attention = {}, sections = {} }
  end,
  colors = function()
    return {}
  end,
  icons = {},
  home = "/home/test",
})
local session_keys = {}
for _, binding in ipairs(session_config.key_tables.sysinit_session_tree) do
  session_keys[binding.key] = binding
end
assert(session_keys["."] and session_keys.x, "session actions are absent from the hidden key table")
assert(session_keys["/"], "slash cannot leave the action layer and enter filtering")
local tree_actions = {}
local tree_window = {
  window_id = function()
    return 7
  end,
  perform_action = function(_, value)
    tree_actions[#tree_actions + 1] = value
  end,
}
session_keys["."].action(tree_window, pane)
assert(#tree_actions == 2, "dot did not leave the session action table before accepting the row")
assert(tree_actions[2].SendKey.key == "Enter", "dot did not accept the selected session row")
tree_actions = {}
session_keys["/"].action(tree_window, pane)
assert(#tree_actions == 2, "slash did not leave the session action table")
assert(tree_actions[2].SendKey.key == "/", "slash did not enter the native filter")

local refreshed
local switch_actions = {}
local function last_switch()
  return switch_actions[#switch_actions]
end
local session_actions = require("sysinit.pkg.ui.actions")
session_actions.set_refresh_handler(function(target)
  refreshed = target
end)
local switch_window = {
  active_workspace = function()
    return "older"
  end,
  perform_action = function(_, value)
    switch_actions[#switch_actions + 1] = value
  end,
}
session_actions.switch_to_workspace(switch_window, pane, "newest")
assert(last_switch().SwitchToWorkspace.name == "newest", "session switch did not target the selected workspace")
assert(last_switch().SwitchToWorkspace.spawn == nil, "a switch with no row invented a spawn")
assert(refreshed == switch_window, "session switch did not refresh the active session indicator")

local launcher = require("sysinit.pkg.ui.launcher")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local function mux_window(name, id)
  return {
    get_workspace = function()
      return name
    end,
    window_id = function()
      return id
    end,
    tabs = function()
      return {}
    end,
    gui_window = function()
      return nil
    end,
  }
end
mux_windows = { mux_window("alpha", 1), mux_window("remote:alpha", 2) }
local calls = 0
child_process = function()
  calls = calls + 1
  error("unexpected process")
end
local tree = require("sysinit.pkg.ui.session_tree").build({})
assert(#tree.workspaces == 2 and calls == 0, "tree discovery must read only the mux")
assert(tree.sections == nil, "directory catalogs leaked into the live tree")
local good_plan =
  { version = "seshy.open/v1", cwd = "/work/a b", command = {}, environment = { SESHY_SESSION = "alpha" } }
local spawn = assert(launcher.directory_spawn(good_plan))
assert(spawn.cwd == "/work/a b" and spawn.args == nil, "directory launch must use the default shell")
assert(spawn.domain.DomainName == "local", "local directory inherited the remote pane domain")
assert(spawn.set_environment_variables.SESHY_SESSION == "alpha", "directory environment was lost")
assert(not launcher.directory_spawn({ version = "other" }), "unknown plan version accepted")
assert(not launcher.directory_spawn({ version = "seshy.open/v1", cwd = "relative" }), "relative path accepted")
local notices, performed, argv = {}, {}, {}
local launch_window = {
  active_workspace = function()
    return "remote:alpha"
  end,
  perform_action = function(_, value)
    performed[#performed + 1] = value
  end,
  toast_notification = function(_, _, text)
    notices[#notices + 1] = text
  end,
}
wezterm.uuid_v4 = function()
  return "unique"
end
child_process = function(args)
  argv[#argv + 1] = args
  return true, args[1], ""
end
json_parse = function(text)
  if text == "list-directories" then
    return { { name = "alpha", path = "/work/a b" } }
  end
  return good_plan
end
launcher.open_directory(launch_window, pane)
local picker = performed[#performed].InputSelector
assert(#picker.choices == 1 and picker.title == "Open directory group", "directory picker did not list groups")
local before = #performed
picker.action(launch_window, pane, nil)
assert(#performed == before and #argv == 1, "cancel resolved or launched a directory")
picker.action(launch_window, pane, "alpha")
local opened = performed[#performed].SwitchToWorkspace
assert(
  opened.spawn.cwd == "/work/a b" and opened.spawn.domain.DomainName == "local",
  "directory selected from remote pane launched remotely"
)
assert(
  argv[2][1] == "open-directory" and argv[2][2] == "alpha" and #argv[2] == 2,
  "selection was not passed as one argument"
)
child_process = function()
  return false, "", "directory disappeared"
end
before = #performed
picker.action(launch_window, pane, "alpha")
assert(
  #performed == before and notices[#notices] == "directory disappeared",
  "failed resolution spawned or hid its error"
)
launcher.connect_host(launch_window, pane, { { name = "ssh:host", remote_address = "host" } })
local host_picker = performed[#performed].InputSelector
host_picker.action(launch_window, pane, "ssh:host")
assert(performed[#performed].AttachDomain == "ssh:host", "host selection did not use its domain")

local ui_format = require("sysinit.pkg.ui.format")
assert(ui_format.smart_path("/state/seshy/sessions/alpha") == "{sy}/alpha", "a configured alias did not abbreviate")
assert(ui_format.smart_path("/state/seshy/sessions") == "{sy}", "an alias did not abbreviate its own directory")
assert(ui_format.smart_path("/state/seshy/sessionsx") == "/state/seshy/sessionsx", "an alias matched a sibling prefix")
assert(ui_format.is_passthrough("zmx") and not ui_format.is_passthrough("nvim"), "passthrough config was ignored")

local ribbon = {
  new = function()
    local parts = {}
    return {
      append = function(_, _, _, text)
        parts[#parts + 1] = text
      end,
      append_items = function() end,
      format = function()
        return table.concat(parts)
      end,
    }
  end,
}
local rows = require("sysinit.pkg.ui.tree_rows").new({ ribbon = ribbon, icons = { session = "W" } })
local targets = {}
local choices = rows(tree, targets, "all", {})
assert(#choices == 2 and targets["ws:alpha"] and targets["ws:remote:alpha"], "live tree rendering lost a workspace")
assert(not targets["ws:directory"], "directory launcher rows leaked into the tree")

local windowtitle = require("sysinit.pkg.ui.windowtitle")
local test_home = os.getenv("HOME") or "/home/test"
local title = windowtitle.format({
  active_pane = {
    foreground_process_name = "/profile/bin/codex",
    current_working_dir = { file_path = test_home .. "/github/personal/roshbhatia/sysinit" },
    title = "reviewing provider changes",
    user_vars = {},
  },
}, nil, "sysinit")
assert(
  title == "codex · sysinit · {gh}/sysinit · reviewing provider changes",
  "the hidden window title lost process, session, cwd, or OSC metadata: " .. title
)
local explicit_title = windowtitle.format({
  active_pane = {
    foreground_process_name = "/profile/bin/nu",
    current_working_dir = { file_path = test_home },
    title = "nu",
    user_vars = { SYSINIT_WINDOW_METADATA = "agent: verifier\nready" },
  },
}, nil, "default")
assert(
  explicit_title == "nu · default · {home} · agent: verifier ready",
  "the hidden window title did not prefer explicit process metadata: " .. explicit_title
)
local invalid = string.char(0xff, 0xc3, 0x28)
local escaped = string.char(0x1b) .. "[31mred" .. string.char(0x1b) .. "[0m"
local hostile_title = windowtitle.format({
  active_pane = {
    foreground_process_name = "/profile/bin/co" .. invalid .. "dex",
    current_working_dir = { file_path = test_home .. "/github/personal/roshbhatia/sy" .. invalid .. "init" },
    title = "ignored",
    user_vars = { SYSINIT_WINDOW_METADATA = escaped .. invalid .. "\nprovider" },
  },
}, nil, "sys" .. string.char(0) .. "init")
assert(utf8.len(hostile_title), "the hidden window title returned invalid UTF-8")
assert(not hostile_title:find("[%c]"), "the hidden window title retained a control byte")
assert(not hostile_title:find("[31m", 1, true), "the hidden window title retained a terminal control sequence")
assert(hostile_title:find("provider", 1, true), "the hidden window title lost sanitized provider metadata")
local pane_title = windowtitle.format({
  active_pane = {
    foreground_process_name = "/profile/bin/codex",
    current_working_dir = { file_path = test_home },
    title = "review " .. invalid .. " ready 🚀",
    user_vars = {},
  },
}, nil, "default")
assert(utf8.len(pane_title), "a malformed pane title produced invalid UTF-8")
assert(pane_title:find("ready 🚀", 1, true), "pane title repair lost later valid Unicode")
local bounded_title = windowtitle.format({
  active_pane = {
    foreground_process_name = string.rep("p", 5000),
    current_working_dir = { file_path = string.rep("d", 5000) },
    title = string.rep("t", 5000),
    user_vars = {},
  },
}, nil, string.rep("s", 5000))
assert(#bounded_title <= 1024, "the hidden window title exceeded its byte bound")
assert(utf8.len(bounded_title), "the bounded window title ended inside a UTF-8 sequence")
assert(not bounded_title:find("……", 1, true), "the window title added duplicate truncation markers")
local boundary_title = windowtitle.format({
  active_pane = {
    foreground_process_name = string.rep("p", 256),
    current_working_dir = { file_path = string.rep("d", 256) },
    title = string.rep("m", 240) .. "🚀x",
    user_vars = {},
  },
}, nil, string.rep("s", 256))
assert(#boundary_title <= 1024, "the Unicode boundary title exceeded its byte bound")
assert(utf8.len(boundary_title), "the window title cutoff split a UTF-8 sequence")
assert(boundary_title:sub(-3) == "…", "the window title cutoff lost its truncation marker")

local event_config = {}
require("sysinit.pkg.events").setup(event_config)
assert(event_config.enable_scroll_bar, "event setup did not enable the scroll bar")

local clipboard
local overrides = { preserved = true }
local get_override_calls = 0
local set_override_calls = 0
local event_action
local event_window = {
  window_id = function()
    return 1
  end,
  copy_to_clipboard = function(_, value, target)
    clipboard = { value = value, target = target }
  end,
  perform_action = function(_, value)
    event_action = value
  end,
  get_config_overrides = function()
    get_override_calls = get_override_calls + 1
    return overrides
  end,
  set_config_overrides = function(_, value)
    set_override_calls = set_override_calls + 1
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
assert(overrides.preserved and overrides.enable_scroll_bar == nil, "the default scroll bar gained an override")
assert(get_override_calls == 1 and set_override_calls == 0, "the initial default scroll bar state was reapplied")
handlers["update-status"](event_window, event_pane)
assert(get_override_calls == 1 and set_override_calls == 0, "an unchanged scroll bar state read or wrote overrides")
alt_screen = true
handlers["update-status"](event_window, event_pane)
assert(not overrides.enable_scroll_bar, "the alternate screen kept the scroll bar")
assert(overrides.preserved, "a scroll bar transition discarded an existing override")
assert(get_override_calls == 2 and set_override_calls == 1, "the hidden scroll bar transition was not applied once")
handlers["update-status"](event_window, event_pane)
assert(get_override_calls == 2 and set_override_calls == 1, "a stable hidden scroll bar reapplied overrides")
alt_screen = false
handlers["update-status"](event_window, event_pane)
assert(overrides.enable_scroll_bar == nil, "the visible scroll bar did not return to its configured default")
assert(overrides.preserved, "restoring the scroll bar discarded an existing override")
assert(get_override_calls == 3 and set_override_calls == 2, "the visible scroll bar transition was not applied once")

local second_overrides = { second_window = true }
local second_get_calls = 0
local second_set_calls = 0
local second_window = {
  window_id = function()
    return 2
  end,
  get_config_overrides = function()
    second_get_calls = second_get_calls + 1
    return second_overrides
  end,
  set_config_overrides = function(_, value)
    second_set_calls = second_set_calls + 1
    second_overrides = value
  end,
}
alt_screen = true
handlers["update-status"](second_window, event_pane)
assert(second_overrides.second_window, "one window's scroll bar discarded another window's override")
assert(second_overrides.enable_scroll_bar == false, "the second window did not hide its scroll bar")
assert(second_get_calls == 1 and second_set_calls == 1, "the second window did not reconcile independently")
handlers["update-status"](second_window, event_pane)
assert(second_get_calls == 1 and second_set_calls == 1, "the second window reapplied a stable override")

local inherited_overrides = { enable_scroll_bar = false, external = "kept" }
local inherited_sets = 0
local inherited_window = {
  window_id = function()
    return 3
  end,
  get_config_overrides = function()
    return inherited_overrides
  end,
  set_config_overrides = function(_, value)
    inherited_sets = inherited_sets + 1
    inherited_overrides = value
  end,
}
alt_screen = false
handlers["update-status"](inherited_window, event_pane)
assert(inherited_sets == 1, "a stale scroll bar override was not reconciled")
assert(inherited_overrides.enable_scroll_bar == nil, "a stale scroll bar override was not removed")
assert(inherited_overrides.external == "kept", "scroll bar reconciliation discarded an external override")
local later_status_ran = false
local stale_pane = {
  get_dimensions = function()
    error("pane id not found in mux")
  end,
}
local stale_ok = pcall(function()
  handlers["update-status"](event_window, stale_pane)
  later_status_ran = true
end)
assert(stale_ok, "a stale pane aborted the update-status event")
assert(later_status_ran, "a stale pane stopped later status handlers")

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
