local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")

local M = {}

M.locked_mode = false

local EDITORS = { "nvim", "vim", "hx" }
local COMMON_MODS = { "CTRL", "SUPER" }

local function create_smart_keybind(key, mods, wezterm_action, opts)
  return {
    key = key,
    mods = mods,
    action = wezterm.action_callback(function(win, pane)
      if M.locked_mode then
        win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
        return
      end

      if opts and opts.passthrough then
        if pane:get_user_vars().IS_NVIM == "true" then
          win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
          return
        end

        local proc = utils.get_process_name(pane)
        for _, p in ipairs(opts.passthrough) do
          if proc == p then
            win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
            return
          end
        end
      end

      win:perform_action(wezterm_action, pane)
    end),
  }
end

local function create_multi_mod_bindings(key, action_fn, mod_list)
  local bindings = {}
  for _, mods in ipairs(mod_list or COMMON_MODS) do
    table.insert(bindings, create_smart_keybind(key, mods, action_fn(mods)))
  end
  return bindings
end

local function get_pane_keys()
  local DIRECTION_KEYS = { h = "Left", j = "Down", k = "Up", l = "Right" }
  local keys = {
    create_smart_keybind("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("m", "CTRL", act.TogglePaneZoomState),
    create_smart_keybind("n", "CTRL", act.RotatePanes("Clockwise")),
  }

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local dir = DIRECTION_KEYS[key]
    table.insert(keys, create_smart_keybind(key, "CTRL", { ActivatePaneDirection = dir }, { passthrough = EDITORS }))
    table.insert(
      keys,
      create_smart_keybind(key, "CTRL|SHIFT", { AdjustPaneSize = { dir, 3 } }, { passthrough = EDITORS })
    )
  end

  for _, binding in
    ipairs(create_multi_mod_bindings("w", function()
      return act.CloseCurrentPane({ confirm = true })
    end))
  do
    table.insert(keys, binding)
  end

  return keys
end

local function read_known_hosts_hosts()
  local hosts = {}
  local seen = {}
  local file = io.open(utils.get_home_dir() .. "/.ssh/known_hosts", "r")
  if not file then
    return hosts
  end

  for line in file:lines() do
    if line ~= "" and not line:match("^%s*#") and not line:match("^|1|") and not line:match("^@") then
      local first = line:match("^(%S+)")
      if first then
        for token in first:gmatch("[^,]+") do
          local host = token:match("^%[([^%]]+)%]") or token
          if host ~= "" and not host:match("[*?]") and not seen[host] then
            seen[host] = true
            table.insert(hosts, host)
          end
        end
      end
    end
  end

  file:close()
  return hosts
end

local function ssh_key_options()
  local opts = {}
  -- The nix-declared agent first: under the GUI $SSH_AUTH_SOCK is wezterm's own
  -- proxy, which holds no identities, so trusting it denies every key.
  local config_data = utils.load_json_file(utils.get_config_path("config.json"))
  local agent = config_data and config_data.ssh and config_data.ssh.agent_socket
  if agent then
    local ok, matches = pcall(wezterm.glob, agent)
    if not ok or #matches == 0 then
      agent = nil
    end
  end
  if not agent or agent == "" then
    agent = os.getenv("SSH_AUTH_SOCK")
  end
  if agent and agent ~= "" then
    opts.identityagent = agent
    -- wezterm defaults identitiesonly to yes, which skips agent auth outright and
    -- leaves only its default id_* list, none of which exists here.
    opts.identitiesonly = "no"
  end
  local home = utils.get_home_dir()
  for _, name in ipairs({ "id_ed25519", "id_ecdsa", "id_rsa" }) do
    local path = home .. "/.ssh/" .. name
    local fh = io.open(path, "r")
    if fh then
      fh:close()
      opts.identityfile = path
      break
    end
  end
  return opts
end

local function build_ssh_domains()
  local key_options = ssh_key_options()
  local domains = {}
  local seen = {} -- host part of ssh:<host> ids already emitted
  local resolved_hostnames = {} -- HostName values behind enumerated aliases

  local function add(host)
    host = host:lower()
    if host == "" or host:match("[*?]") or seen[host] or resolved_hostnames[host] then
      return
    end
    seen[host] = true
    table.insert(domains, {
      name = "ssh:" .. host,
      remote_address = host,
      multiplexing = "WezTerm",
      assume_shell = "Posix",
      ssh_option = key_options,
    })
  end

  local ok, hosts = pcall(wezterm.enumerate_ssh_hosts)
  if ok and hosts then
    for host, cfg in pairs(hosts) do
      if not host:match("%.host") then
        if type(cfg) == "table" and cfg.hostname then
          resolved_hostnames[cfg.hostname:lower()] = true
        end
        add(host)
      end
    end
  end

  for _, host in ipairs(read_known_hosts_hosts()) do
    add(host)
  end

  return domains
end

-- The viewer chords.
local function pane_cwd(pane)
  local ok, path = pcall(function()
    local url = pane:get_current_working_dir()
    if not url then
      return nil
    end
    if type(url) == "string" then
      return (url:gsub("^file://[^/]*", ""))
    end
    return url.file_path
  end)
  if not ok or not path or path == "" then
    return nil
  end
  return (path:gsub("/+$", ""))
end

local function watch_keybind(key, describe, build_args)
  return {
    key = key,
    mods = "SUPER|SHIFT",
    action = wezterm.action_callback(function(win, pane)
      if M.locked_mode then
        win:perform_action({ SendKey = { key = key, mods = "SUPER|SHIFT" } }, pane)
        return
      end
      local args = build_args(pane)
      if not args then
        win:toast_notification("sysinit", "nothing to watch: " .. describe, nil, 3000)
        return
      end
      table.insert(args, 1, utils.get_nix_binary("sysinit-agent"))
      table.insert(args, 2, "watch")
      win:perform_action(act.SplitPane({ direction = "Right", command = { args = args } }), pane)
    end),
  }
end

local function get_system_keys()
  return {
    create_smart_keybind("r", "SUPER", act.ReloadConfiguration),
    create_smart_keybind(":", "SUPER", act.ActivateCommandPalette),
    create_smart_keybind(";", "SUPER", act.ActivateCommandPalette),
    create_smart_keybind(";", "CTRL", act.ActivateCommandPalette),
    {
      key = "e",
      mods = "SUPER",
      action = wezterm.action_callback(function(win, pane)
        if M.locked_mode then
          win:perform_action({ SendKey = { key = "e", mods = "SUPER" } }, pane)
          return
        end
        local dims = pane:get_dimensions()
        local lines = pane:get_lines_as_text(dims.scrollback_rows + dims.viewport_rows)
        local tmp = os.tmpname() .. ".txt"
        local f = io.open(tmp, "w")
        if f then
          f:write(lines)
          f:close()
        end
        local editor = os.getenv("EDITOR") or utils.get_nix_binary("nvim")
        local argv = { editor, tmp }
        local ok, split = pcall(wezterm.shell_split, editor)
        if ok and split and #split > 0 then
          argv = split
          table.insert(argv, tmp)
        end
        win:perform_action(act.SpawnCommandInNewTab({ args = argv }), pane)
      end),
    },
    create_smart_keybind("c", "SUPER", act.CopyTo("Clipboard")),
    create_smart_keybind("c", "CTRL|SHIFT", act.CopyTo("Clipboard")),
    create_smart_keybind("h", "SUPER", act.HideApplication),
    create_smart_keybind("k", "SUPER", act.ClearScrollback("ScrollbackAndViewport"), { passthrough = EDITORS }),
    create_smart_keybind("m", "SUPER", act.Hide),
    create_smart_keybind("q", "SUPER", act.QuitApplication),
    create_smart_keybind("v", "SUPER", act.PasteFrom("Clipboard")),
    create_smart_keybind("v", "CTRL|SHIFT", act.PasteFrom("Clipboard")),
    watch_keybind("w", "no working directory", function(pane)
      -- The worker is keyed on the workspace, so this passes the same thing `bus`
      -- does. Passing the viewer's own pane id read the record of whichever pane
      -- pressed the chord, which is the wrong one whenever that is not the pane
      -- that ran the command.
      local cwd = pane_cwd(pane)
      if not cwd then
        return nil
      end
      return { "worker", cwd }
    end),
    watch_keybind("b", "no working directory", function(pane)
      local cwd = pane_cwd(pane)
      if not cwd then
        return nil
      end
      return { "bus", cwd }
    end),
  }
end

local function get_font_keys()
  local keys = {}
  for _, binding in
    ipairs(create_multi_mod_bindings("-", function()
      return act.DecreaseFontSize
    end))
  do
    table.insert(keys, binding)
  end
  for _, binding in
    ipairs(create_multi_mod_bindings("=", function()
      return act.IncreaseFontSize
    end))
  do
    table.insert(keys, binding)
  end
  return keys
end

local function get_tab_keys()
  local keys = {
    create_smart_keybind("w", "CTRL|SHIFT", act.CloseCurrentTab({ confirm = true })),
    create_smart_keybind("Tab", "CTRL", act.ActivateTabRelative(1)),
    create_smart_keybind("Tab", "CTRL|SHIFT", act.ActivateTabRelative(-1)),
    create_smart_keybind("o", "CTRL|SHIFT", act.ActivateLastTab),
  }

  table.insert(keys, create_smart_keybind("t", "CTRL", act.SpawnTab("CurrentPaneDomain")))

  table.insert(keys, create_smart_keybind("t", "SUPER", act.SpawnTab("CurrentPaneDomain")))

  table.insert(keys, create_smart_keybind("t", "CTRL|SHIFT", act.ShowTabNavigator))

  table.insert(keys, create_smart_keybind("t", "SUPER|SHIFT", act.SpawnTab({ DomainName = "local" })))

  table.insert(
    keys,
    create_smart_keybind(
      "r",
      "CTRL|SHIFT",
      act.PromptInputLine({
        description = "Rename tab:",
        action = wezterm.action_callback(function(win, _, line)
          if line then
            win:active_tab():set_title(line)
          end
        end),
      })
    )
  )
  table.insert(
    keys,
    create_smart_keybind(
      "r",
      "SUPER|SHIFT",
      act.PromptInputLine({
        description = "Rename tab:",
        action = wezterm.action_callback(function(win, _, line)
          if line then
            win:active_tab():set_title(line)
          end
        end),
      })
    )
  )

  table.insert(keys, create_smart_keybind(",", "CTRL|SHIFT", act.MoveTabRelative(-1)))
  table.insert(keys, create_smart_keybind(".", "CTRL|SHIFT", act.MoveTabRelative(1)))

  for i = 1, 9 do
    local tab_action = i == 9 and act.ActivateTab(-1) or act.ActivateTab(i - 1)
    for _, binding in
      ipairs(create_multi_mod_bindings(tostring(i), function()
        return tab_action
      end))
    do
      table.insert(keys, binding)
    end
  end

  return keys
end

local function get_window_keys()
  return {
    create_smart_keybind("n", "SUPER", act.SpawnWindow),
    create_smart_keybind("n", "SUPER|SHIFT", act.SpawnCommandInNewWindow({ domain = { DomainName = "local" } })),
  }
end

local function get_search_keys()
  return {
    create_smart_keybind("Escape", "CTRL", act.ActivateCopyMode),
    create_smart_keybind("/", "CTRL", act.Search("CurrentSelectionOrEmptyString")),
    create_smart_keybind("f", "CTRL", act.QuickSelect),
    create_smart_keybind("f", "CTRL|SHIFT", act.PaneSelect),
  }
end

local function get_scroll_keys()
  return {
    create_smart_keybind("u", "CTRL", { ScrollByLine = -40 }, { passthrough = EDITORS }),
    create_smart_keybind("d", "CTRL", { ScrollByLine = 40 }, { passthrough = EDITORS }),
    create_smart_keybind("u", "CTRL|SHIFT", act.ScrollToTop, { passthrough = EDITORS }),
    create_smart_keybind("d", "CTRL|SHIFT", act.ScrollToBottom, { passthrough = EDITORS }),
    create_smart_keybind("UpArrow", "CTRL|SHIFT", act.ScrollToPrompt(-1), { passthrough = EDITORS }),
    create_smart_keybind("DownArrow", "CTRL|SHIFT", act.ScrollToPrompt(1), { passthrough = EDITORS }),
  }
end

local function merge_keys(...)
  local result = {}
  for _, group in ipairs({ ... }) do
    for _, key in ipairs(group) do
      table.insert(result, key)
    end
  end
  return result
end

function M.setup(config)
  config.disable_default_key_bindings = true

  local keys = merge_keys(
    get_system_keys(),
    get_font_keys(),
    get_pane_keys(),
    get_scroll_keys(),
    get_search_keys(),
    get_tab_keys(),
    get_window_keys()
  )

  table.insert(keys, {
    key = "g",
    mods = "CTRL",
    action = wezterm.action_callback(function()
      M.locked_mode = not M.locked_mode
    end),
  })

  config.ssh_domains = build_ssh_domains()

  config.enable_kitty_keyboard = true

  config.keys = keys

  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}

  config.bypass_mouse_reporting_modifiers = "SHIFT"

  config.mouse_bindings = {
    {
      event = { Down = { streak = 3, button = "Left" } },
      action = act.SelectTextAtMouseCursor("SemanticZone"),
      mods = "NONE",
    },
    {
      event = { Down = { streak = 1, button = "Left" } },
      mods = "SHIFT",
      action = act.SelectTextAtMouseCursor("Cell"),
    },
    {
      event = { Drag = { streak = 1, button = "Left" } },
      mods = "SHIFT",
      action = act.ExtendSelectionToMouseCursor("Cell"),
    },
    {
      event = { Up = { streak = 1, button = "Left" } },
      mods = "SHIFT",
      action = act.CompleteSelection("ClipboardAndPrimarySelection"),
    },
  }
end

return M
