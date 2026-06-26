local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")
local plugin_loader = require("sysinit.pkg.plugin_loader")

local M = {}

M.locked_mode = false

-- smart_ssh.wezterm module, loaded in M.setup. Its M.tab() returns an
-- InputSelector "Choose Host" action over the configured ssh_domains.
local smart_ssh = nil

-- Constants
-- Processes that should receive raw key events instead of wezterm actions
local EDITORS = { "nvim", "vim", "hx" }
-- Modifier keys used when generating bindings for both terminal and GUI contexts
local COMMON_MODS = { "CTRL", "SUPER" }

-- Create a smart keybind that respects locked mode and passthrough processes.
-- key:              the key to bind
-- mods:             modifier string (e.g. "CTRL", "SUPER")
-- wezterm_action:   the action to perform when no override applies
-- opts.passthrough: list of process names that should receive the raw keystroke
local function create_smart_keybind(key, mods, wezterm_action, opts)
  return {
    key = key,
    mods = mods,
    action = wezterm.action_callback(function(win, pane)
      -- In locked mode every keybind is forwarded as-is to the pane
      if M.locked_mode then
        win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
        return
      end

      if opts and opts.passthrough then
        local proc = utils.get_process_name(pane)
        for _, p in ipairs(opts.passthrough) do
          if proc == p then
            win:perform_action({ SendKey = { key = key, mods = mods } }, pane)
            return
          end
        end
      end

      -- No overrides matched; execute the intended wezterm action
      win:perform_action(wezterm_action, pane)
    end),
  }
end

-- Helper: Create multiple bindings for the same key with different modifiers
local function create_multi_mod_bindings(key, action_fn, mod_list)
  local bindings = {} -- accumulator table for the generated keybind entries
  for _, mods in ipairs(mod_list or COMMON_MODS) do -- iterate each modifier string, falling back to CTRL + SUPER when mod_list is nil
    table.insert(bindings, create_smart_keybind(key, mods, action_fn(mods))) -- invoke action_fn with the current modifier to produce the wezterm action, then build and append the smart keybind
  end
  return bindings -- return the completed list of bindings to the caller
end

local function get_pane_keys()
  local DIRECTION_KEYS = { h = "Left", j = "Down", k = "Up", l = "Right" }
  local keys = {
    create_smart_keybind("s", "CTRL", act.SplitVertical({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("v", "CTRL", act.SplitHorizontal({ domain = "CurrentPaneDomain" })),
    create_smart_keybind("m", "CTRL", act.TogglePaneZoomState),
    create_smart_keybind("n", "CTRL", act.RotatePanes("Clockwise")),
  }

  -- Navigation and resize for h, j, k, l
  for _, key in ipairs({ "h", "j", "k", "l" }) do
    local dir = DIRECTION_KEYS[key]
    table.insert(keys, create_smart_keybind(key, "CTRL", { ActivatePaneDirection = dir }, { passthrough = EDITORS }))
    table.insert(
      keys,
      create_smart_keybind(key, "CTRL|SHIFT", { AdjustPaneSize = { dir, 3 } }, { passthrough = EDITORS })
    )
  end

  -- Close pane with CTRL/SUPER
  for _, binding in
    ipairs(create_multi_mod_bindings("w", function()
      return act.CloseCurrentPane({ confirm = true })
    end))
  do
    table.insert(keys, binding)
  end

  return keys
end

-- Parse ~/.ssh/known_hosts into bare host names usable as an SSH: exec domain.
-- Lines look like `host1,host2,[host3]:2222 ssh-ed25519 AAAA... comment`; we
-- take only the comma-separated host field, dropping hashed entries (`|1|...`,
-- unreadable as names), comments/CA markers (`#`/`@...`), and wildcards. The
-- bracketed `[host]:port` form is unwrapped to the bare host.
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

-- libssh ssh_options that let WezTerm's built-in SSH client authenticate with a
-- key instead of prompting for a password. WezTerm's libssh transport does not
-- read ~/.ssh/config reliably, so we hand it the ssh-agent socket and the first
-- existing default identity file explicitly. Empty when neither is present (a
-- bare {} is harmless on a domain).
local function ssh_key_options()
  local opts = {}
  local agent = os.getenv("SSH_AUTH_SOCK")
  if agent and agent ~= "" then
    opts.identityagent = agent
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

-- Assemble the SSH domain set smart_ssh's picker draws from (it reads the mux
-- domains whose name starts with "ssh"). We mirror smart_ssh's own domain shape
-- — lowercase "ssh:<host>", Posix shell — so its formatter (name:sub(5)) renders
-- the bare host, attach ssh_option for key auth, and coverage-merge
-- ~/.ssh/known_hosts hosts that enumerate_ssh_hosts misses (wildcard-only Host
-- blocks, hosts only ever connected to; wezterm#5553).
--
-- multiplexing = "WezTerm": persistent/reattachable mux domains (require remote
-- wezterm-mux-server). These are the hosts we control (our tailnet), so the mux
-- bootstrap is available; selecting one still opens a new tab via smart_ssh.
--
-- Merge: ~/.ssh/config aliases its Host entries to tailnet FQDNs (e.g. arrakis
-- -> arrakis.stork-eel.ts.net). enumerate returns the aliases AND their resolved
-- hostname, so we record every resolved hostname and skip the known_hosts FQDN
-- that maps back to an alias already added — collapsing the duplicate.
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
      -- smart_ssh skips the synthetic "*.host" wildcard entries enumerate emits.
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

-- SSH picker: smart_ssh.wezterm's fuzzy "Choose Host" InputSelector over the
-- configured ssh_domains (seeded in M.setup from build_ssh_domains). Falls back
-- to WezTerm's native fuzzy launcher if smart_ssh failed to load.
local function get_ssh_picker()
  if smart_ssh then
    return smart_ssh.tab()
  end
  return act.ShowLauncherArgs({ flags = "FUZZY|DOMAINS" })
end

local function get_system_keys()
  return {
    create_smart_keybind("r", "SUPER", act.ReloadConfiguration),
    create_smart_keybind(":", "SUPER", act.ActivateCommandPalette),
    create_smart_keybind(";", "SUPER", act.ActivateCommandPalette),
    create_smart_keybind(";", "CTRL", act.ActivateCommandPalette),
    -- SUPER+SHIFT+s: ssh host picker. SUPER+s is reserved for the workspace /
    -- seshy switcher, bound in ui.lua where the configured plugin instance lives.
    {
      key = "s",
      mods = "SUPER|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if M.locked_mode then
          win:perform_action({ SendKey = { key = "s", mods = "SUPER|SHIFT" } }, pane)
          return
        end
        win:perform_action(get_ssh_picker(), pane)
      end),
    },
    -- SUPER+E: open scrollback buffer in $EDITOR in a new tab
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

  -- New tab with CTRL in current domain
  table.insert(keys, create_smart_keybind("t", "CTRL", act.SpawnTab("CurrentPaneDomain")))

  -- New tab with SUPER (CMD) in current domain
  table.insert(keys, create_smart_keybind("t", "SUPER", act.SpawnTab("CurrentPaneDomain")))

  -- Fuzzy tab switcher on CTRL|SHIFT+t
  table.insert(keys, create_smart_keybind("t", "CTRL|SHIFT", act.ShowTabNavigator))

  -- SUPER|SHIFT+t: always spawn a new tab in the local domain (bypass SSH/remote)
  table.insert(keys, create_smart_keybind("t", "SUPER|SHIFT", act.SpawnTab({ DomainName = "local" })))

  -- Rename current tab
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

  -- Reorder tabs
  table.insert(keys, create_smart_keybind(",", "CTRL|SHIFT", act.MoveTabRelative(-1)))
  table.insert(keys, create_smart_keybind(".", "CTRL|SHIFT", act.MoveTabRelative(1)))

  -- Tab switching: 1-8 go to specific tabs, 9 goes to last tab
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
    -- SUPER|SHIFT+n: spawn a new window in the local domain (SpawnWindow uses DefaultDomain)
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
    -- Jump between shell prompt boundaries (requires OSC 133 shell integration)
    create_smart_keybind("UpArrow", "CTRL|SHIFT", act.ScrollToPrompt(-1), { passthrough = EDITORS }),
    create_smart_keybind("DownArrow", "CTRL|SHIFT", act.ScrollToPrompt(1), { passthrough = EDITORS }),
  }
end

-- Merge all key groups into a single table
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

  -- Collect all keybindings
  local keys = merge_keys(
    get_system_keys(),
    get_font_keys(),
    get_pane_keys(),
    get_scroll_keys(),
    get_search_keys(),
    get_tab_keys(),
    get_window_keys()
  )

  -- Add locked mode toggle
  table.insert(keys, {
    key = "g",
    mods = "CTRL",
    action = wezterm.action_callback(function()
      M.locked_mode = not M.locked_mode
    end),
  })

  -- Load smart_ssh.wezterm: powers the SUPER+SHIFT+s fuzzy host picker
  -- (get_ssh_picker). Its picker reads the configured ssh_domains below.
  local smart_ssh_ok, smart_ssh_mod = plugin_loader.load("smart-ssh")
  if smart_ssh_ok then
    smart_ssh = smart_ssh_mod
  else
    wezterm.log_warn("Failed to load smart_ssh.wezterm: " .. tostring(smart_ssh_mod))
  end

  -- Seed the SSH domain set the SUPER+SHIFT+s picker draws from.
  config.ssh_domains = build_ssh_domains()

  -- Enable kitty keyboard protocol for richer key event reporting (mod keys, etc.)
  config.enable_kitty_keyboard = true

  -- Apply the merged keybindings table
  config.keys = keys

  -- Seed key_tables with WezTerm's built-in defaults (copy-mode, search-mode, etc.);
  -- guard against headless / non-GUI contexts where wezterm.gui is nil
  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}

  -- Plain (NONE-modifier) drags are intentionally forwarded to mouse-capturing
  -- TUIs (e.g. Claude Code fullscreen) so their own click-to-expand / URL click /
  -- wheel scroll keep working. SHIFT+drag is the select-to-copy gesture: it
  -- bypasses in-app mouse reporting and copies to the system clipboard. SHIFT is
  -- already WezTerm's default bypass modifier; set it explicitly to document intent.
  config.bypass_mouse_reporting_modifiers = "SHIFT"

  -- Triple-click selects a semantic zone (shell prompt / command output boundary)
  -- rather than the default line-select behaviour. mouse_bindings merges with
  -- WezTerm's defaults rather than replacing them.
  config.mouse_bindings = {
    {
      event = { Down = { streak = 3, button = "Left" } },
      action = act.SelectTextAtMouseCursor("SemanticZone"),
      mods = "NONE",
    },
    -- SHIFT+drag select-to-copy under app mouse reporting. Bind Down/Drag/Up
    -- together to avoid WezTerm's documented "Up-only" double-fire gotcha, and
    -- complete to ClipboardAndPrimarySelection so the selection lands on the
    -- macOS system clipboard (the default left-release only fills PrimarySelection).
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
