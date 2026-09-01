local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")

local M = {}

M.locked_mode = false

local EDITORS = { "nvim", "vim", "hx" }

-- A ctrl chord that readline or an editor already owns is passed to the app.
-- READLINE is for the chords that also have a SUPER twin, so the wezterm action
-- stays reachable from a shell prompt; the rest get EDITORS only, because in a
-- terminal the pane is nearly always a shell and a shell passthrough would make
-- the chord unreachable.
local SHELLS = { "zsh", "bash", "fish", "sh", "nu" }
local READLINE = (function()
  local both = {}
  for _, name in ipairs(EDITORS) do
    both[#both + 1] = name
  end
  for _, name in ipairs(SHELLS) do
    both[#both + 1] = name
  end
  return both
end)()

local TRACE_NAV = (function()
  local both = {}
  for _, name in ipairs(EDITORS) do
    both[#both + 1] = name
  end
  both[#both + 1] = "traces"
  both[#both + 1] = "orc"
  return both
end)()

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

local function create_multi_mod_bindings(key, action_fn, mod_list, opts)
  local bindings = {}
  for _, mods in ipairs(mod_list or COMMON_MODS) do
    -- Only the CTRL half can collide with a terminal convention, so only it
    -- carries the passthrough. The SUPER half must always reach wezterm.
    local per = mods == "CTRL" and opts or nil
    table.insert(bindings, create_smart_keybind(key, mods, action_fn(mods), per))
  end
  return bindings
end

local function get_pane_keys()
  local DIRECTION_KEYS = { h = "Left", j = "Down", k = "Up", l = "Right" }
  local keys = {
    -- CTRL-s is XOFF and CTRL-v is blockwise visual; CTRL-n is next-completion.
    -- Editors get them back. A shell keeps the split, because a shell pane is
    -- where you split from.
    create_smart_keybind("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" }), {
      passthrough = EDITORS,
    }),
    create_smart_keybind("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" }), {
      passthrough = EDITORS,
    }),

    create_smart_keybind("s", "CTRL|SHIFT", act.SplitPane({ direction = "Down", top_level = true }), {
      passthrough = EDITORS,
    }),
    create_smart_keybind("v", "CTRL|SHIFT", act.SplitPane({ direction = "Right", top_level = true }), {
      passthrough = EDITORS,
    }),
    -- CTRL-m is a carriage return, but nothing types it instead of Enter, and a
    -- passthrough would cost pane zoom inside an editor. Left bound on purpose.
    create_smart_keybind("m", "CTRL", act.TogglePaneZoomState),
    create_smart_keybind("n", "CTRL", act.RotatePanes("Clockwise"), { passthrough = EDITORS }),
  }

  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local dir = DIRECTION_KEYS[key]
    table.insert(keys, create_smart_keybind(key, "CTRL", { ActivatePaneDirection = dir }, { passthrough = TRACE_NAV }))
    table.insert(
      keys,
      create_smart_keybind(key, "CTRL|SHIFT", { AdjustPaneSize = { dir, 3 } }, { passthrough = EDITORS })
    )
  end

  for _, binding in
    -- CTRL-w is the editor window prefix and readline's kill-word. SUPER-w
    -- closes the pane, so the chord loses nothing by passing through.
    ipairs(create_multi_mod_bindings("w", function()
      return act.CloseCurrentPane({ confirm = true })
    end, nil, { passthrough = READLINE }))
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
  local seen = {}
  local resolved_hostnames = {}

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
      table.insert(args, 1, utils.get_nix_binary("utils"))
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
    create_smart_keybind(
      "k",
      "SUPER",
      act.Multiple({
        act.ClearScrollback("ScrollbackAndViewport"),
        act.SendKey({ key = "l", mods = "CTRL" }),
      }),
      { passthrough = EDITORS }
    ),
    create_smart_keybind("m", "SUPER", act.Hide),
    create_smart_keybind("q", "SUPER", act.QuitApplication),
    create_smart_keybind("v", "SUPER", act.PasteFrom("Clipboard")),
    watch_keybind("w", "no working directory", function(pane)
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

  -- CTRL-t is fzf's file widget and readline's transpose. SUPER-t spawns the
  -- tab, so the chord loses nothing by passing through.
  table.insert(keys, create_smart_keybind("t", "CTRL", act.SpawnTab("CurrentPaneDomain"), { passthrough = READLINE }))

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
    -- CTRL-/ is readline undo and CTRL-f is page-forward in an editor.
    create_smart_keybind("/", "CTRL", act.Search("CurrentSelectionOrEmptyString"), {
      passthrough = EDITORS,
    }),
    create_smart_keybind("f", "CTRL", act.QuickSelect, { passthrough = EDITORS }),
    create_smart_keybind("f", "CTRL|SHIFT", act.PaneSelect),
  }
end

local function get_scroll_keys()
  return {
    -- CTRL-u is kill-line and CTRL-d is EOF, and a shell prompt needs both far
    -- more than it needs a half-page scroll. SUPER-u and SUPER-d keep the scroll
    -- reachable from the prompt, so the passthrough costs nothing.
    create_smart_keybind("u", "CTRL", { ScrollByLine = -40 }, { passthrough = READLINE }),
    create_smart_keybind("d", "CTRL", { ScrollByLine = 40 }, { passthrough = READLINE }),
    create_smart_keybind("u", "SUPER", { ScrollByLine = -40 }),
    create_smart_keybind("d", "SUPER", { ScrollByLine = 40 }),
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

  -- CTRL-g is readline's abort, and it stays bound: it is the switch that turns
  -- every other binding into a passthrough, so it cannot itself pass through.
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
