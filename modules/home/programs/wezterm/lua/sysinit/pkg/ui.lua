local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local plugin_loader = require("sysinit.pkg.plugin_loader")
local ui_actions = require("sysinit.pkg.ui.actions")
local ui_badges = require("sysinit.pkg.ui.badges")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
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
      agents = {
        claude = {
          patterns = { ".claude%-wrapped", "claude", "claude%-code" },
          executable_patterns = { "@anthropic%-ai/claude%-code", "/claude%-code/", "/claude$", "claude" },
          argv_patterns = { "@anthropic%-ai/claude%-code", "claude%-code", "^claude%s*$" },
          title_patterns = { "claude code", "claude", ".claude%-wrapped" },
        },
        goose = {
          patterns = { "goose", "goosed" },
          executable_patterns = { "/goose$", "/goosed$" },
          argv_patterns = { "^goose%s*$" },
          title_patterns = { "goose" },
        },
        amp = {
          patterns = { "amp" },
          executable_patterns = { "/amp$" },
          argv_patterns = { "^amp%s*$" },
          title_patterns = { "amp" },
        },
        copilot = {
          patterns = { "copilot" },
          executable_patterns = { "/copilot$", "copilot%-language%-server" },
          argv_patterns = { "^copilot%s*$" },
          title_patterns = { "copilot" },
        },
        cursor = {
          patterns = { "cursor%-agent", "cursor" },
          executable_patterns = { "/cursor%-agent$" },
          argv_patterns = { "cursor%-agent" },
          title_patterns = { "cursor" },
        },
        crush = {
          patterns = { "crush" },
          executable_patterns = { "/crush$" },
          argv_patterns = { "^crush%s*$" },
          title_patterns = { "crush" },
        },
        gemini = {
          patterns = { "antigravity", "agy", "gemini" },
          executable_patterns = { "/agy$", "antigravity%-cli" },
          argv_patterns = { "^agy%s*$" },
          title_patterns = { "antigravity", "gemini" },
        },
        devin = {
          patterns = { "devin" },
          executable_patterns = { "/devin$" },
          argv_patterns = { "^devin%s*$" },
          title_patterns = { "devin" },
        },
      },
    })

    local notified = {}
    wezterm.on("update-status", function()
      local ok, deck_states = pcall(agent_deck.get_all_agent_states)
      if not ok or type(deck_states) ~= "table" then
        return
      end
      for _, win in ipairs(wezterm.mux.all_windows()) do
        for _, tab in ipairs(win:tabs()) do
          for _, p in ipairs(tab:panes()) do
            local id = p:pane_id()
            local deck = deck_states[id]
            if deck and (deck.status == "waiting" or deck.status == "done") then
              local uv = p:get_user_vars()
              if not (uv and uv.agent_state and uv.agent_state ~= "") then
                if notified[id] ~= deck.status then
                  notified[id] = deck.status
                  local reason = deck.status == "waiting" and "idle" or "done"
                  wezterm.background_child_process({
                    utils.get_nix_binary("agent-notify"),
                    deck.agent or "agent",
                    reason,
                    utils.get_nix_binary("agent-focus"),
                  })
                end
              end
            elseif deck == nil or deck.status == "working" then
              notified[id] = nil
            end
          end
        end
      end
    end)

    local function publish_selection()
      local ok_ws, ws = pcall(wezterm.mux.get_active_workspace)
      if not ok_ws or type(ws) ~= "string" or ws == "" then
        return
      end
      local state = utils.state_path("agents", "agents")
      pcall(function()
        os.execute("mkdir -p " .. ("%q"):format(state))
      end)
      pcall(function()
        local f = io.open(state .. "/selected.json", "w")
        if not f then
          return
        end
        f:write(string.format('{"selected":%s,"heartbeat":%d}\n', wezterm.json_encode(ws), os.time()))
        f:close()
      end)
    end

    wezterm.on("update-status", function(_window, _pane)
      publish_selection()
      local all_states = agent_deck.get_all_agent_states()
      local active_ids = {}
      local ok = pcall(function()
        for _, win in ipairs(wezterm.mux.all_windows()) do
          for _, tab in ipairs(win:tabs()) do
            for _, p in ipairs(tab:panes()) do
              active_ids[p:pane_id()] = true
            end
          end
        end
      end)
      if not ok then
        return
      end
      for pane_id in pairs(all_states) do
        if not active_ids[pane_id] then
          all_states[pane_id] = nil
        end
      end
    end)
  end

  local nf = wezterm.nerdfonts or {}
  local agent_state_icons = ui_format.state_icons
  local agent_state_labels = ui_format.state_labels
  local agent_state_rank = ui_panes.state_rank
  local status_color = ui_format.status_color
  local format_status_label = ui_format.status_label
  local format_age = ui_format.age

  local pane_repo = ui_panes.pane_repo
  local read_pane_record = ui_panes.read_pane_record

  local smart_path = ui_format.smart_path

  local pane_agent_state = ui_panes.agent_state

  local function deck_states()
    return agent_deck_ok and agent_deck.get_all_agent_states() or {}
  end

  local function agent_session_states()
    return ui_rollup.states(deck_states)
  end

  local gui_window_for_workspace = ui_actions.gui_window_for_workspace
  local switch_to_workspace = ui_actions.switch_to_workspace
  local activate_agent_pane = ui_actions.activate_agent_pane

  local normalize_proc = ui_format.normalize_proc
  local pane_proc = ui_format.pane_proc
  local tab_label = ui_format.tab_label

  local seshy_session_names = ui_sessions.list_names
  local seshy_names_cached = ui_sessions.names_cached
  local active_session_names = ui_sessions.active_names
  local session_slots = ui_sessions.slots
  local touch_workspace = ui_sessions.touch
  local workspace_last_active = ui_sessions.last_active
  local seshy_dir = ui_sessions.seshy_dir
  local sy_bin = ui_sessions.sy_bin
  local DEFAULT_WORKSPACE = ui_sessions.DEFAULT_WORKSPACE
  local DEFAULT_SLOT = ui_sessions.DEFAULT_SLOT
  local MAX_SLOT = ui_sessions.MAX_SLOT
  local home = os.getenv("HOME") or ""

  wezterm.on("update-status", function(window, _pane)
    local ok, focused = pcall(function()
      return window:is_focused()
    end)
    if (not ok) or focused then
      pcall(function()
        touch_workspace(window:active_workspace())
      end)
    end
    ui_sessions.refresh_remote()
  end)

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

  local function activate_slot(win, pane, slot)
    local target
    for name, s in pairs(session_slots()) do
      if s == slot then
        target = name
        break
      end
    end
    if not target then
      return
    end
    local live = false
    pcall(function()
      for _, w in ipairs(wezterm.mux.all_windows()) do
        if w:get_workspace() == target then
          live = true
        end
      end
    end)
    local spawn = nil
    if not live and target ~= DEFAULT_WORKSPACE then
      spawn = ui_sessions.remote_spawn(target) or { cwd = seshy_dir .. "/" .. target }
    end
    switch_to_workspace(win, pane, target, spawn)
  end

  -- Stepping by slot rather than by workspace name walks the same order the
  -- session chips are drawn in, and wraps at both ends.
  local function step_session(win, pane, step)
    local taken = {}
    for _, slot in pairs(session_slots()) do
      taken[#taken + 1] = slot
    end
    table.sort(taken)
    if #taken < 2 then
      return
    end

    local here = session_slots()[win:active_workspace()]
    local at = 1
    for index, slot in ipairs(taken) do
      if slot == here then
        at = index
        break
      end
    end

    activate_slot(win, pane, taken[(at - 1 + step) % #taken + 1])
  end

  config.keys = config.keys or {}
  for slot = DEFAULT_SLOT, MAX_SLOT do
    table.insert(config.keys, {
      key = "phys:" .. tostring(slot),
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if keybindings.locked_mode then
          win:perform_action({ SendKey = { key = tostring(slot), mods = "CTRL|SHIFT" } }, pane)
          return
        end
        activate_slot(win, pane, slot)
      end),
    })
  end

  for _, one in ipairs({
    { key = "phys:LeftBracket", send = "[", step = -1 },
    { key = "phys:RightBracket", send = "]", step = 1 },
  }) do
    table.insert(config.keys, {
      key = one.key,
      mods = "CTRL|SHIFT",
      action = wezterm.action_callback(function(win, pane)
        if keybindings.locked_mode then
          win:perform_action({ SendKey = { key = one.send, mods = "CTRL|SHIFT" } }, pane)
          return
        end
        step_session(win, pane, one.step)
      end),
    })
  end

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

  local pane_badge = ui_badges.name
  local pane_badge_color = ui_badges.color

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
