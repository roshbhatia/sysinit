local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("sysinit.pkg.utils")

local M = {}

M.locked_mode = false

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

-- Assemble the SSH domain set the launcher draws from. Start with WezTerm's
-- generated domains (one SSH: exec + one SSHMUX: multiplexer per host
-- enumerate_ssh_hosts finds in ~/.ssh/config), force a Posix shell assumption
-- for cwd awareness, then coverage-merge known_hosts entries that
-- enumerate_ssh_hosts misses (wildcard-only Host blocks, hosts only ever
-- connected to) as SSH: exec domains. enumerate_ssh_hosts never reads
-- known_hosts and drops wildcard/Match blocks (wezterm#5553, #5755).
local function build_ssh_domains()
  local domains = wezterm.default_ssh_domains()
  local seen_hosts = {}

  for _, dom in ipairs(domains) do
    dom.assume_shell = "Posix"
    -- default_ssh_domains names each domain "SSH:<host>" / "SSHMUX:<host>";
    -- record the bare host so the merge below does not re-add it.
    local host = dom.name:match("^SSH[^:]*:(.+)$")
    if host then
      seen_hosts[host] = true
    end
  end

  for _, host in ipairs(read_known_hosts_hosts()) do
    if not seen_hosts[host] then
      seen_hosts[host] = true
      table.insert(domains, {
        name = "SSH:" .. host,
        remote_address = host,
        multiplexing = "None", -- exec domain: do not assume remote wezterm
        assume_shell = "Posix",
      })
    end
  end

  return domains
end

-- SSH picker: WezTerm's native fuzzy launcher over the configured ssh_domains
-- (seeded in M.setup from build_ssh_domains). FUZZY alone opens an empty
-- launcher (wezterm#2377); the DOMAINS content flag is what populates it.
local function get_ssh_picker()
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

  -- Seed the SSH domain set the SUPER+SHIFT+s fuzzy launcher draws from.
  config.ssh_domains = build_ssh_domains()

  -- Enable kitty keyboard protocol for richer key event reporting (mod keys, etc.)
  config.enable_kitty_keyboard = true

  -- Apply the merged keybindings table
  config.keys = keys

  -- Seed key_tables with WezTerm's built-in defaults (copy-mode, search-mode, etc.);
  -- guard against headless / non-GUI contexts where wezterm.gui is nil
  config.key_tables = wezterm.gui and wezterm.gui.default_key_tables() or {}

  -- Triple-click selects a semantic zone (shell prompt / command output boundary)
  -- rather than the default line-select behaviour
  config.mouse_bindings = {
    {
      event = { Down = { streak = 3, button = "Left" } },
      action = act.SelectTextAtMouseCursor("SemanticZone"),
      mods = "NONE",
    },
  }
end

return M
