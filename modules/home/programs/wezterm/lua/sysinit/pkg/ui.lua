local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local plugin_loader = require("sysinit.pkg.plugin_loader")
local ui_actions = require("sysinit.pkg.ui.actions")
local ui_session_tree = require("sysinit.pkg.ui.session_tree")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local ui_statusbar = require("sysinit.pkg.ui.statusbar")
local ui_tabtitle = require("sysinit.pkg.ui.tabtitle")
local ui_switcher = require("sysinit.pkg.ui.switcher")
local ui_rollup = require("sysinit.pkg.ui.rollup")

local M = {}

function M.setup(config)
  local config_data = utils.load_json_file(utils.get_config_path("config.json"))
  local font = wezterm.font_with_fallback({
    {
      family = config_data.font.monospace,
      harfbuzz_features = { "calt", "liga" },
    },
    config_data.font.symbols,
  })

  config.font = font
  config.font_size = 11.0
  config.line_height = 1.0
  config.cell_width = 1.0

  if config_data.colors then
    config.colors = config_data.colors
  end

  config.inactive_pane_hsb = {
    saturation = 0.8,
    brightness = 0.65,
  }

  config.status_update_interval = 150
  config.animation_fps = 240
  config.max_fps = 240
  config.cursor_blink_rate = 320
  config.cursor_thickness = 1
  config.scrollback_lines = 200000
  config.quick_select_alphabet = "fjdkslaghrueiwoncmv"
  config.adjust_window_size_when_changing_font_size = false
  config.use_resize_increments = false
  config.pane_focus_follows_mouse = false

  config.tab_bar_at_bottom = true
  config.use_fancy_tab_bar = false
  config.hide_tab_bar_if_only_one_tab = false

  config.default_workspace = "default"

  config.window_frame = {
    font = font,
    font_size = 11.0,
  }

  config.visual_bell = {
    fade_in_function = "EaseIn",
    fade_in_duration_ms = 70,
    fade_out_function = "EaseOut",
    fade_out_duration_ms = 100,
  }

  config.window_background_opacity = config_data.transparency.opacity

  if utils.is_darwin() then
    config.front_end = "WebGpu"
    config.window_decorations = "RESIZE|MACOS_FORCE_ENABLE_SHADOW"
    config.macos_window_background_blur = config_data.transparency.blur
  else
    config.enable_wayland = false
    config.front_end = "WebGpu"
    config.window_decorations = "RESIZE"
    config.freetype_load_flags = "NO_HINTING|NO_AUTOHINT"
    config.tiling_desktop_environments = {
      "X11 LG3D",
      "X11 bspwm",
      "X11 i3",
      "X11 dwm",
      "Wayland",
    }
  end

  local function locked_indicator()
    if keybindings.locked_mode then
      return "  "
    end
    return "  "
  end

  local agent_deck_ok, agent_deck = plugin_loader.load("agent-deck")
  if not agent_deck_ok then
    wezterm.log_warn("Failed to load agent-deck: " .. tostring(agent_deck))
  end
  if agent_deck_ok then
    agent_deck.apply_to_config(config, {
      tab_title = { enabled = false },
      right_status = { enabled = false },
      cooldown_ms = 150,
      max_lines = 500,
      notifications = {
        enabled = false,
        on_waiting = false,
        backend = "native",
      },
      agents = config_data.agents or {},
    })
  end

  local nf = wezterm.nerdfonts or {}

  local function deck_states()
    return agent_deck_ok and agent_deck.get_all_agent_states() or {}
  end

  local function agent_session_states()
    return ui_rollup.states(deck_states)
  end

  -- One walk per tick, over the rollup's per-second cache. Three separate
  -- `update-status` handlers each used to walk every window, tab and pane at
  -- the 150ms status interval, and one of them shelled out to mkdir every time.
  local notified = {}
  -- A pane that never worked has nothing to wait on; without this a fresh agent
  -- pane reads as "waiting" the moment it opens and notifies on every session start.
  local worked = {}
  local selection_at = -1
  local selection_dir = utils.state_path("agents", "agents")
  wezterm.background_child_process({ "/bin/mkdir", "-p", selection_dir })

  -- The pane the user is looking at right now, or nil when no window has focus.
  local function focused_pane_id()
    local ok, id = pcall(function()
      for _, win in ipairs(wezterm.mux.all_windows()) do
        local gui = win:gui_window()
        if gui and gui:is_focused() then
          local p = win:active_pane()
          return p and p:pane_id() or nil
        end
      end
      return nil
    end)
    return ok and id or nil
  end

  local function publish_selection(now)
    if now - selection_at < 5 then
      return
    end
    selection_at = now
    local ok_ws, ws = pcall(wezterm.mux.get_active_workspace)
    if not ok_ws or type(ws) ~= "string" or ws == "" then
      return
    end
    pcall(function()
      local f = io.open(selection_dir .. "/selected.json", "w")
      if not f then
        return
      end
      f:write(string.format('{"selected":%s,"heartbeat":%d}\n', wezterm.json_encode(ws), now))
      f:close()
    end)
  end

  wezterm.on("update-status", function(window)
    local now = os.time()
    publish_selection(now)

    local ok_focus, focused = pcall(function()
      return window:is_focused()
    end)
    if (not ok_focus) or focused then
      pcall(function()
        ui_sessions.touch(window:active_workspace())
      end)
    end
    ui_sessions.refresh_remote()

    local _, panes = agent_session_states()
    local live = {}
    -- Resolved at most once per tick, and only when something is actually
    -- pending, so an idle mux does no window walk at all.
    local on_screen, on_screen_known = nil, false

    for _, rec in ipairs(panes) do
      local id = rec.pane_id
      live[id] = true
      -- A harness hook owns its own notification, so only a screen-scraped
      -- state gets one from here. Notifying on both double-fires.
      if rec.source == "deck" then
        if rec.status == "working" then
          notified[id] = nil
          worked[id] = true
        elseif (rec.status == "waiting" or rec.status == "done") and worked[id] and notified[id] ~= rec.status then
          if not on_screen_known then
            on_screen, on_screen_known = focused_pane_id(), true
          end
          -- Recorded either way. Suppressing a state you already watched happen
          -- is the point; leaving it unrecorded would just fire it the moment
          -- you looked somewhere else.
          notified[id] = rec.status
          if id ~= on_screen then
            local reason = rec.status == "waiting" and "idle" or "done"
            wezterm.background_child_process({
              utils.get_nix_binary("agent-notify"),
              rec.agent ~= "" and rec.agent or "agent",
              reason,
              utils.get_nix_binary("agent-focus"),
              tostring(id),
              rec.cwd or "",
            })
          end
        end
      end
    end

    for id in pairs(notified) do
      if not live[id] then
        notified[id] = nil
      end
    end
    for id in pairs(worked) do
      if not live[id] then
        worked[id] = nil
      end
    end
  end)

  local session_slots = ui_sessions.slots
  local DEFAULT_SLOT = ui_sessions.DEFAULT_SLOT
  local MAX_SLOT = ui_sessions.MAX_SLOT
  local home = os.getenv("HOME") or ""

  local function session_tree()
    return ui_session_tree.build(deck_states())
  end

  local function tree_colors(win)
    return ui_session_tree.colors(win, config_data)
  end
  local function agent_status()
    return ui_statusbar.agent_status(agent_session_states())
  end

  local function session_chips(window)
    return ui_statusbar.session_chips(window, agent_session_states(), session_slots(), tree_colors(window))
  end

  config.keys = config.keys or {}
  -- Sessions sit one SHIFT above tabs: a tab is CTRL or SUPER plus a digit, and
  -- a session is the same chord plus SHIFT. Both mods carry it, the way the tab
  -- digits already do.
  for slot = DEFAULT_SLOT, MAX_SLOT do
    for _, mods in ipairs({ "CTRL|SHIFT", "SUPER|SHIFT" }) do
      table.insert(config.keys, {
        key = "phys:" .. tostring(slot),
        mods = mods,
        action = wezterm.action_callback(function(win, pane)
          if keybindings.locked_mode then
            win:perform_action({ SendKey = { key = tostring(slot), mods = mods } }, pane)
            return
          end
          ui_actions.activate_slot(win, pane, slot)
        end),
      })
    end
  end

  -- No SUPER bracket cycle, and this is the third and last home for one. cmd+[
  -- and cmd+] are back and forward in Finder, in every browser and in most
  -- macOS apps, so a wezterm binding costs the chord everywhere. Stepping is
  -- now [ and ] inside the session tree, where a session step is already the
  -- obvious next key. c70f54052 put it on CTRL and lost Escape; f25aed814 put
  -- it on SUPER and lost it to hammerspoon.

  local tabline_ok, tabline = plugin_loader.load("tabline")
  if not tabline_ok then
    wezterm.log_warn("Failed to load tabline.wez: " .. tostring(tabline))
  end
  if tabline_ok then
    tabline.setup({
      options = {
        theme = config.colors,
        tabs_enabled = true,
        section_separators = {
          left = "",
          right = "",
        },
        component_separators = {
          left = "",
          right = "",
        },
        tab_separators = {
          left = " ",
          right = " ",
        },
      },
      sections = {
        tabline_a = {
          "mode",
          locked_indicator,
        },
        tabline_b = {},
        tabline_c = {},
        tabline_x = { agent_status, session_chips, "ResetAttributes" },
        tabline_y = {},
        tabline_z = { "domain" },
        tab_active = {
          "index",
          { "parent", padding = 0 },
          "/",
          { "cwd", padding = { left = 0, right = 1 } },
        },
        tab_inactive = {
          "index",
          { "cwd", padding = { left = 0, right = 1 } },
        },
      },
      extensions = {},
    })
    tabline.apply_to_config(config)
  end

  if not tabline_ok then
    wezterm.on("update-right-status", function(window, _pane)
      local mode_text = locked_indicator()
      window:set_right_status(wezterm.format({
        { Text = mode_text },
      }))
    end)
  end

  if utils.is_darwin() then
    config.window_padding = {
      left = "1cell",
      right = "1cell",
      top = "1cell",
      bottom = "0cell",
    }
  end

  plugin_loader.load("warp")
  local ribbon_ok, ribbon = plugin_loader.load("ribbon")
  if not ribbon_ok then
    wezterm.log_warn("Failed to load ribbon.wz: " .. tostring(ribbon))
  end
  local sigil_ok, sigil = plugin_loader.load("sigil")
  if not sigil_ok then
    wezterm.log_warn("Failed to load sigil.wz: " .. tostring(sigil))
  end
  if sigil_ok then
    sigil.setup({
      overrides = {
        claude = {
          name = "Claude",
          icon = "✳",
          color = "#D97757",
          aliases = { ".claude-wrapped", "claude-code", "claude-wrapped" },
        },
        codex = {
          name = "Codex",
          icon = nf.md_robot or "C",
          color = "#10A37F",
          aliases = { ".codex-wrapped", "codex-wrapped", "codex" },
        },
      },
    })
  end

  local tree_icons = {
    session = (sigil_ok and sigil.symbol("Workspace")) or nf.cod_briefcase or "",
    dormant = nf.md_sleep or "󰒲",
    tab = nf.md_tab or "󰓩",
    folder = (sigil_ok and sigil.symbol("Folder")) or nf.md_folder or "",
    attn = nf.md_alert or "󰀪",
    branch = nf.cod_git_branch or "⎇",
  }

  wezterm.GLOBAL = wezterm.GLOBAL or {}
  wezterm.GLOBAL.__lantern_plugin_dir = config_data.plugins and config_data.plugins.lantern
  local lantern_ok, lantern = plugin_loader.load("lantern")
  if not lantern_ok then
    wezterm.log_warn("Failed to load lantern.wz: " .. tostring(lantern))
  end
  if lantern_ok then
    lantern.setup({
      log = { enabled = false },
      default_font = { font_size = config.font_size },
      color = { opacity = config_data.transparency.opacity },
    })
    lantern.rekindle(config)

    local lantern_categories = {
      { id = "colorscheme", label = "Colorscheme", fn = lantern.light.colorscheme },
      { id = "font", label = "Font", fn = lantern.light.font },
      { id = "font_size", label = "Font size", fn = lantern.light.font_size },
      { id = "font_leading", label = "Font leading", fn = lantern.light.font_leading },
      { id = "font_ligatures", label = "Font ligatures", fn = lantern.light.font_ligatures },
      { id = "gpu", label = "GPU / front end", fn = lantern.light.gpu },
      { id = "window_opacity", label = "Window opacity", fn = lantern.light.window_opacity },
      { id = "window_padding", label = "Window padding", fn = lantern.light.window_padding },
      { id = "inactive_pane_opacity", label = "Inactive pane opacity", fn = lantern.light.inactive_pane_opacity },
      { id = "cursor_style", label = "Cursor style", fn = lantern.light.cursor_style },
      { id = "tab_bar_style", label = "Tab bar style", fn = lantern.light.tab_bar_style },
    }

    config.keys = config.keys or {}
    table.insert(config.keys, {
      key = "l",
      mods = "SUPER|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if keybindings.locked_mode then
          win:perform_action({ SendKey = { key = "l", mods = "SUPER|SHIFT" } }, pane)
          return
        end
        local choices = {}
        for _, cat in ipairs(lantern_categories) do
          choices[#choices + 1] = { id = cat.id, label = cat.label }
        end
        win:perform_action(
          wezterm.action.InputSelector({
            title = "Appearance",
            fuzzy = true,
            choices = choices,
            action = wezterm.action_callback(function(inner_win, inner_pane, id, _label)
              if not id then
                return
              end
              for _, cat in ipairs(lantern_categories) do
                if cat.id == id then
                  inner_win:perform_action(cat.fn(), inner_pane)
                  return
                end
              end
            end),
          }),
          pane
        )
      end),
    })
  end

  wezterm.on("format-tab-title", function(tab, _tabs, _panes, cfg, _hover, _max_width)
    return ui_tabtitle.format(tab, cfg, {
      home = home,
      sigil_ok = sigil_ok,
      sigil = sigil,
      ribbon_ok = ribbon_ok,
      ribbon = ribbon,
    })
  end)

  local hyperlink_rules = wezterm.default_hyperlink_rules()

  table.insert(hyperlink_rules, {
    regex = [[(/nix/store/[a-z0-9]{32}[a-zA-Z0-9._+%-][^\s]*)]],
    format = "file://$1",
  })

  table.insert(hyperlink_rules, {
    regex = [[([a-zA-Z0-9_.-]+/[a-zA-Z0-9_.-]+)#([0-9]+)]],
    format = "https://github.com/$1/issues/$2",
  })

  config.hyperlink_rules = hyperlink_rules

  config.quick_select_patterns = {
    "/nix/store/[a-z0-9]{32}[a-zA-Z0-9._+%-][^\\s]*",
    "[0-9a-f]{40}",
    "(?<![0-9a-f])[0-9a-f]{7}(?![0-9a-f])",
    "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}",
    "/[^\\s]+",
  }

  local wm_ok, wm = plugin_loader.load("workspace-manager")
  if not wm_ok then
    wezterm.log_warn("Failed to load workspace-manager.wezterm: " .. tostring(wm))
  end
  if wm_ok then
    ui_switcher.setup(config, wm, {
      sessions = agent_session_states,
      tree = session_tree,
      colors = tree_colors,
      icons = tree_icons,
      home = home,
      sigil_ok = sigil_ok,
      sigil = sigil,
      ribbon = ribbon,
    })
  end
end

return M
