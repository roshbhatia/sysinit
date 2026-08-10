local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local plugin_loader = require("sysinit.pkg.plugin_loader")
local ui_badges = require("sysinit.pkg.ui.badges")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
local ui_session_tree = require("sysinit.pkg.ui.session_tree")
local ui_sessions = require("sysinit.pkg.ui.sessions")
local ui_statusbar = require("sysinit.pkg.ui.statusbar")
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
      if not ok or type(deck_states) ~= "table" then return end
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
                    os.getenv("HOME") .. "/.nix-profile/bin/agent-notify",
                    deck.agent or "agent",
                    reason,
                    os.getenv("HOME") .. "/.nix-profile/bin/agent-focus",
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

  -- Reads the OSC user variable, which wezterm has already base64-decoded,
  -- and falls back to the agent-deck plugin. Schema: pkgs/sysinit-agent/internal/agentstate/SCHEMA.md.
  -- The variable is authoritative here because it is live and dies with the
  -- pane, so it needs no liveness rule.
  local pane_agent_state = ui_panes.agent_state

  local function deck_states()
    return agent_deck_ok and agent_deck.get_all_agent_states() or {}
  end

  local function agent_session_states()
    return ui_rollup.states(deck_states)
  end

  local function gui_window_for_workspace(workspace)
    if not workspace or workspace == "" then
      return nil
    end
    local windows = {}
    pcall(function()
      windows = wezterm.mux.all_windows()
    end)
    for _, w in ipairs(windows) do
      local ok_ws, ws = pcall(function()
        return w:get_workspace()
      end)
      if ok_ws and ws == workspace then
        local ok_gui, gui = pcall(function()
          return w:gui_window()
        end)
        if ok_gui and gui then
          return gui
        end
      end
    end
    return nil
  end

  local function switch_to_workspace(win, pane, name, spawn_cwd)
    if not name or name == "" then
      return
    end
    local ok_active, active = pcall(function()
      return win:active_workspace()
    end)
    if ok_active and active == name then
      return
    end
    local gui = gui_window_for_workspace(name)
    if gui then
      pcall(function()
        gui:focus()
      end)
      return
    end
    local act = spawn_cwd and wezterm.action.SwitchToWorkspace({ name = name, spawn = { cwd = spawn_cwd } })
      or wezterm.action.SwitchToWorkspace({ name = name })
    win:perform_action(act, pane)
  end

  local function activate_agent_pane(win, gui_pane, rec)
    if not rec or not rec.pane_id then
      return
    end
    local mux_win
    pcall(function()
      local mp = wezterm.mux.get_pane(rec.pane_id)
      if not mp then
        return
      end
      local tab = mp:tab()
      if tab then
        tab:activate()
        mux_win = tab:window()
      end
      mp:activate()
    end)
    local gui
    if mux_win then
      pcall(function()
        gui = mux_win:gui_window()
      end)
    end
    if gui then
      pcall(function()
        gui:focus()
      end)
      return
    end
    switch_to_workspace(win, gui_pane, rec.workspace)
  end

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
        local spawn_cwd = nil
        if not live and target ~= DEFAULT_WORKSPACE then
          spawn_cwd = seshy_dir .. "/" .. target
        end
        switch_to_workspace(win, pane, target, spawn_cwd)
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
        tabline_z = {},
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
    tab     = nf.md_tab or "󰓩",
    folder  = (sigil_ok and sigil.symbol("Folder")) or nf.md_folder or "",
    attn    = nf.md_alert or "󰀪",
    branch  = nf.cod_git_branch or "⎇",
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

  local SHELLS = { zsh = true, bash = true, fish = true, sh = true, ["-zsh"] = true }

  wezterm.on("format-tab-title", function(tab, _tabs, _panes, cfg, _hover, _max_width)
    local pane = tab.active_pane
    local explicit = normalize_proc(tab.tab_title or "")
    local osc = normalize_proc(pane and pane.title or "")
    local proc = pane and pane.foreground_process_name
    if proc then proc = normalize_proc(proc:match("([^/]+)$") or proc) end

    if explicit ~= "" and not explicit:match("^%d+$") then
      return explicit
    end

    local dir
    local cwd_uri = pane and pane.current_working_dir
    if cwd_uri then
      local cwd = cwd_uri.file_path or tostring(cwd_uri)
      if home ~= "" and cwd == home then
        dir = "~"
      else
        dir = cwd:match("([^/]+)/?$") or cwd
      end
    end

    local label
    if osc and osc ~= "" and not osc:match("^%d+$") and not SHELLS[osc:lower()] then
      label = osc
    end
    label = label or dir or proc or "shell"

    if not (sigil_ok and ribbon_ok) then
      return label
    end

    local r = ribbon.new("tab")

    pcall(function()
      local uv = pane and pane.user_vars
      local raw = uv and uv.agent_state
      if not raw or raw == "" then return end
      local s = raw:match("^([^|]*)|")
      local icon = s and s ~= "idle" and agent_state_icons[s]
      if icon then r:append(nil, nil, icon .. " ") end
    end)

    if pane and pane.is_zoomed then
      r:append(nil, nil, nf.md_dock_window and (nf.md_dock_window .. " ") or "⊞ ")
    end

    if proc then
      local icon_items = sigil.items(proc, { padding = "right", fallback = false, reset = true })
      if icon_items and #icon_items > 0 then
        r:append_items(icon_items)
      end
    end

    r:append(nil, nil, label)

    if pane and pane.pane_id then
      local pid = pane.pane_id
      local bc = pane_badge_color(pid, cfg and cfg.colors or {})
      if bc then
        r:append(nil, "#3b4261", "  ")
        r:append(nil, bc, pane_badge(pid))
      end
    end

    return r:items()
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

    wm.get_choices = function()
      local sessions, panes = agent_session_states()
      local now = os.time()

      local agg = {}
      for _, rec in ipairs(panes) do
        local a = agg[rec.workspace]
        if not a then
          a = { count = 0, blocked = 0, repo = "", agent = "", worst_rank = 0, worst_status = nil }
          agg[rec.workspace] = a
        end
        a.count = a.count + 1
        if a.repo == "" and rec.repo ~= "" then
          a.repo = rec.repo
        end
        if rec.rank >= agent_state_rank.working then
          a.blocked = a.blocked + 1
        end
        if rec.rank > a.worst_rank then
          a.worst_rank = rec.rank
          a.worst_status = rec.status
          if rec.agent ~= "" then
            a.agent = rec.agent
          end
        end
      end

      local default_choice = { name = "default", path = home, label = "default" }
      local rows = {}

      for _, name in ipairs(seshy_session_names(sy_bin)) do
        if name ~= "default" then
          local st = sessions[name]
          local label = name
          if st then
            local icon = agent_state_icons[st.status] or "●"
            label = icon .. " " .. name
            local a = agg[name]
            if a then
              if a.repo ~= "" then label = label .. "  at " .. a.repo end
              if a.agent ~= "" then label = label .. "  in " .. a.agent end
            end
            local age = st.since and format_age(now - st.since) or ""
            local fmt = format_status_label(st.status, st.reason)
            if fmt ~= "" then label = label .. "  — " .. fmt end
            if age ~= "" then label = label .. "  " .. age end
          end
          table.insert(rows, {
            name = name,
            path = seshy_dir .. "/" .. name,
            label = label,
            _rank = st and st.rank or 0,
            _since = st and st.since or nil,
          })
        end
      end

      table.sort(rows, function(a, b)
        if a._rank ~= b._rank then
          return a._rank > b._rank
        end
        if a._rank > 0 and a._since ~= b._since then
          return (a._since or now) < (b._since or now)
        end
        return a.name < b.name
      end)

      local choices = { default_choice }
      for _, row in ipairs(rows) do
        table.insert(choices, { name = row.name, path = row.path, label = row.label })
      end
      return choices
    end

    local function attn_row(rec, now, colors)
      local sc = status_color(rec.status, colors) or colors.idle
      local icon = agent_state_icons[rec.status] or "●"
      local is_urgent = rec.rank and rec.rank >= agent_state_rank.working
      local age = rec.since and format_age(now - rec.since) or ""

      local r = ribbon.new("attn")
      if is_urgent then
        r:append(nil, colors.waiting, tree_icons.attn .. " ")
      else
        r:append(nil, nil, "  ")
      end
      r:append(nil, sc, icon .. " ")
      local crumb = rec.workspace
      if rec.tab_title ~= "" then crumb = crumb .. " · " .. rec.tab_title end
      r:append(nil, colors.name, crumb, "Bold")
      local attn_dp = smart_path(rec.cwd)
      if attn_dp == "" then attn_dp = rec.repo end
      if attn_dp ~= "" and attn_dp ~= rec.tab_title then
        r:append(nil, colors.chrome, "  ")
        r:append(nil, colors.age, "at ")
        r:append(nil, colors.name, attn_dp)
      end
      if rec.branch then
        r:append(nil, colors.chrome, "  ")
        r:append(nil, colors.age, "on ")
        r:append(nil, colors.age, rec.branch)
        if rec.dirty then r:append(nil, colors.working, " *") end
      end
      if rec.title ~= "" then
        r:append(nil, colors.chrome, "  ")
        r:append(nil, colors.age, "in ")
        if sigil_ok then
          local proc_items = sigil.items(rec.title, { fallback = true, padding = "right", reset = true })
          r:append_items(proc_items)
        end
        r:append(nil, colors.name, rec.title)
      end
      local fmt = format_status_label(rec.status, rec.reason)
      if fmt ~= "" then r:append(nil, colors.reason, "  " .. fmt) end
      if age ~= "" then
        r:append(nil, colors.age, "  " .. age)
      end
      local bc = pane_badge_color(rec.pane_id, colors)
      if bc then
        r:append(nil, colors.chrome, "  ")
        r:append(nil, bc, pane_badge(rec.pane_id))
      end
      return r:format()
    end

    local function session_tree_choices(tree, by_id, filter, colors)
      local choices = {}
      local now = os.time()
      local function add(id, label, rec)
        by_id[id] = rec or true
        choices[#choices + 1] = { id = id, label = label }
      end
      filter = filter or "all"

      if filter == "blocked" or filter == "agents" then
        local list = {}
        if filter == "blocked" then
          for _, rec in ipairs(tree.attention) do list[#list + 1] = rec end
        else
          for _, ws in ipairs(tree.workspaces) do
            for _, tnode in ipairs(ws.tabs) do
              for _, rec in ipairs(tnode.panes) do
                if rec.status then list[#list + 1] = rec end
              end
            end
          end
          table.sort(list, function(a, b)
            if a.rank ~= b.rank then return a.rank > b.rank end
            return (a.since or now) < (b.since or now)
          end)
        end
        for _, rec in ipairs(list) do
          add("pane:" .. rec.pane_id, attn_row(rec, now, colors), rec)
        end
        return choices
      end

      if filter == "dormant" then
        for _, ws in ipairs(tree.workspaces) do
          if ws.dormant then
            local r = ribbon.new("dormant")
            r:append(nil, colors.ws_dorm, tree_icons.dormant .. " " .. ws.name)
            add("ws:" .. ws.name, r:format(), { workspace = ws.name, dormant = true })
          end
        end
        return choices
      end

      if filter == "sessions" then
        local live = {}
        for _, ws in ipairs(tree.workspaces) do
          if not ws.dormant then live[#live + 1] = ws end
        end
        table.sort(live, function(a, b)
          return (a.last_active or 0) > (b.last_active or 0)
        end)
        for i, ws in ipairs(live) do
          local sc = status_color(ws.status, colors)
          local qs = i <= 9 and tostring(i) or string.char(96 + i - 9)
          local r = ribbon.new("ws")
          r:append(nil, colors.chrome, qs .. "  ")
          r:append(nil, sc or colors.ws_live, tree_icons.session .. " ")
          r:append(nil, colors.name, ws.name, "Bold")
          if ws.status then
            r:append(nil, sc or colors.working, "  " .. (agent_state_icons[ws.status] or "●"))
          end
          local age = ws.last_active and format_age(now - ws.last_active) or ""
          if age ~= "" then
            r:append(nil, colors.age, "  " .. age)
          end
          add("ws:" .. ws.name, r:format(), { workspace = ws.name, dormant = false })
        end
        return choices
      end

      local live_sorted = {}
      for _, ws in ipairs(tree.workspaces) do
        if not ws.dormant then live_sorted[#live_sorted + 1] = ws end
      end
      table.sort(live_sorted, function(a, b)
        return (a.last_active or 0) > (b.last_active or 0)
      end)

      for _, ws in ipairs(live_sorted) do
          local sc = status_color(ws.status, colors)
          local ws_r = ribbon.new("ws")
          ws_r:append(nil, sc or colors.ws_live, tree_icons.session .. " ")
          ws_r:append(nil, colors.name, ws.name, { "Bold", "Single" })
          if ws.status then
            local ws_lbl = agent_state_labels[ws.status] or ""
            ws_r:append(nil, colors.chrome, "  ")
            ws_r:append(nil, sc or colors.working, agent_state_icons[ws.status] or "●")
            if ws_lbl ~= "" then
              ws_r:append(nil, colors.reason, " " .. ws_lbl)
            end
          end
          add("ws:" .. ws.name, ws_r:format(), { workspace = ws.name, dormant = false })

          for ti, tnode in ipairs(ws.tabs) do
            local tlast = ti == #ws.tabs
            local tbranch = tlast and "  └─ " or "  ├─ "
            local tab_r = ribbon.new("tab")
            tab_r:append(nil, colors.chrome, tbranch)
            tab_r:append(nil, colors.ws_live, tree_icons.tab)
            tab_r:append(nil, colors.chrome, " [" .. tostring(ti) .. "]")
            tab_r:append(nil, colors.chrome, "  ")
            tab_r:append(nil, colors.name, tnode.title)
            add("tab:" .. tnode.tab_id, tab_r:format(), { pane_id = tnode.active_pane_id, workspace = ws.name })

            for pi, rec in ipairs(tnode.panes) do
              local pbranch = (tlast and "     " or "  │  ")
                .. (pi == #tnode.panes and "└─ " or "├─ ")
              local pane_r = ribbon.new("pane")
              pane_r:append(nil, colors.chrome, pbranch)
              local bc = pane_badge_color(rec.pane_id, colors)
              if bc then
                pane_r:append(nil, colors.chrome, "<")
                pane_r:append(nil, bc, pane_badge(rec.pane_id))
                pane_r:append(nil, colors.chrome, ">")
              end
              local pane_dp = smart_path(rec.cwd)
              if pane_dp == "" then pane_dp = rec.repo end
              if pane_dp ~= "" then
                pane_r:append(nil, colors.chrome, "  ")
                pane_r:append(nil, colors.age, "at ")
                pane_r:append(nil, colors.name, pane_dp)
              end
              if rec.branch then
                pane_r:append(nil, colors.chrome, "  ")
                pane_r:append(nil, colors.age, "on ")
                pane_r:append(nil, colors.age, rec.branch)
                if rec.dirty then pane_r:append(nil, colors.working, " *") end
              end
              local proc = rec.title ~= "" and rec.title or nil
              if proc then
                pane_r:append(nil, colors.chrome, "  ")
                pane_r:append(nil, colors.age, "in ")
                if sigil_ok then
                  local proc_items = sigil.items(proc, { fallback = true, padding = "right", reset = true })
                  pane_r:append_items(proc_items)
                end
                pane_r:append(nil, colors.name, proc)
              end
              if rec.status then
                local asc = status_color(rec.status, colors) or colors.idle
                local p_fmt = format_status_label(rec.status, rec.reason)
                pane_r:append(nil, colors.chrome, "  ")
                pane_r:append(nil, asc, agent_state_icons[rec.status] or "●")
                if p_fmt ~= "" then
                  pane_r:append(nil, colors.reason, " " .. p_fmt)
                end
                if rec.status ~= "done" then
                  local age = rec.since and format_age(now - rec.since) or ""
                  if age ~= "" then pane_r:append(nil, colors.age, " " .. age) end
                end
              end
              add("pane:" .. rec.pane_id, pane_r:format(), rec)
            end
          end
      end

      return choices
    end

    local function session_tree_dispatch(win, pane, id, by_id)
      if not id then
        return
      end
      local rec = by_id[id]
      if type(rec) ~= "table" then
        return
      end
      local kind = id:match("^([^:]+):")
      if kind == "ws" and rec.dormant then
        switch_to_workspace(win, pane, rec.workspace, seshy_dir .. "/" .. rec.workspace)
      elseif kind == "ws" then
        switch_to_workspace(win, pane, rec.workspace)
      else
        activate_agent_pane(win, pane, rec)
      end
    end

    local tree_state = { pending_filter = nil, pending_action = nil, current_filter = "all", key_table_active = false }
    local function tree_close_key(key)
      return {
        key = key,
        mods = "NONE",
        action = wezterm.action_callback(function(win, pane)
          tree_state.pending_filter = nil
          tree_state.key_table_active = false
          win:perform_action(wezterm.action.PopKeyTable, pane)
          win:perform_action(wezterm.action.SendKey({ key = key }), pane)
        end),
      }
    end
    config.key_tables = config.key_tables or {}
    config.key_tables.session_tree_actions = {
      tree_close_key("Enter"),
      tree_close_key("Escape"),
      {
        key = "d",
        mods = "CTRL",
        action = wezterm.action_callback(function(win, pane)
          tree_state.pending_filter = tree_state.current_filter == "dormant" and "all" or "dormant"
          tree_state.key_table_active = false
          win:perform_action(wezterm.action.PopKeyTable, pane)
          win:perform_action(wezterm.action.SendKey({ key = "Enter" }), pane)
        end),
      },
      {
        key = "x",
        mods = "CTRL",
        action = wezterm.action_callback(function(win, pane)
          tree_state.pending_action = "delete"
          tree_state.key_table_active = false
          win:perform_action(wezterm.action.PopKeyTable, pane)
          win:perform_action(wezterm.action.SendKey({ key = "Enter" }), pane)
        end),
      },
    }

    local function close_session_target(id, by_id)
      local rec = by_id[id]
      if type(rec) ~= "table" or not rec.workspace then
        return "not a session row"
      end
      local name = rec.workspace
      if rec.dormant then
        return "already dormant: " .. name
      end
      if gui_window_for_workspace(name) then
        return "cannot close a visible session"
      end
      local wezterm_bin = (wezterm.executable_dir or "") .. "/wezterm"
      local ok, stdout = wezterm.run_child_process({ wezterm_bin, "cli", "list", "--format=json" })
      if not ok then
        wezterm.log_error("wezterm cli list failed; workspace " .. name .. " left open")
        return "close failed: " .. name
      end
      local killed = 0
      for _, p in ipairs(wezterm.json_parse(stdout) or {}) do
        if p.workspace == name then
          local kill_ok = wezterm.run_child_process({
            wezterm_bin,
            "cli",
            "kill-pane",
            "--pane-id=" .. tostring(p.pane_id),
          })
          if kill_ok then
            killed = killed + 1
          end
        end
      end
      if killed == 0 then
        return "no panes found: " .. name
      end
      return "closed " .. name
    end

    local function open_session_tree(win, pane, filter, notice)
      filter = filter or "all"
      tree_state.current_filter = filter
      local tree = session_tree()
      local colors = tree_colors(win)
      local by_id = {}
      local choices = session_tree_choices(tree, by_id, filter, colors)
      if #choices == 0 then
        if filter and filter ~= "all" then
          filter, by_id = "all", {}
          choices = session_tree_choices(tree, by_id, "all", colors)
        end
        if #choices == 0 then
          return
        end
      end
      local title
      if filter == "dormant" then
        title = "Sessions  [dormant · ^d all · ^x close]"
      else
        title = "Sessions  [^d dormant · ^x close]"
      end
      if notice then
        title = title .. "  · " .. notice
      end
      tree_state.pending_filter = nil
      tree_state.key_table_active = true
      win:perform_action(
        wezterm.action.ActivateKeyTable({ name = "session_tree_actions", one_shot = false }),
        pane
      )
      win:perform_action(
        wezterm.action.InputSelector({
          title = title,
          choices = choices,
          fuzzy = false,
          description = "  j/k nav  1-9 jump  / filter  ^d dormant  ^x close  Esc quit",
          fuzzy_description = "  filter (Esc to leave):  ",
          action = wezterm.action_callback(function(inner_win, inner_pane, id, _label)
            if tree_state.key_table_active then
              tree_state.key_table_active = false
              inner_win:perform_action(wezterm.action.PopKeyTable, inner_pane)
            end
            local pa = tree_state.pending_action
            tree_state.pending_action = nil
            local pf = tree_state.pending_filter
            tree_state.pending_filter = nil
            if pa == "delete" and id then
              local close_notice = close_session_target(id, by_id)
              wezterm.time.call_after(0.15, function()
                open_session_tree(inner_win, inner_pane, tree_state.current_filter, close_notice)
              end)
              return
            end
            if pf then
              wezterm.time.call_after(0.05, function()
                open_session_tree(inner_win, inner_pane, pf)
              end)
              return
            end
            session_tree_dispatch(inner_win, inner_pane, id, by_id)
          end),
        }),
        pane
      )
    end

    wm.session_enabled = true
    wm.session_restore_on_startup = false
    wm.session_state_dir = utils.state_path("weztermWorkspaceState", "wezterm/workspace_state")
    wm.workspace_switcher_sort = "recency"

    wm.apply_to_config(config)
    local wm_injected_keys = {
      { key = "s", mods = "LEADER" },
      { key = "S", mods = "LEADER" },
      { key = "]", mods = "CTRL" },
      { key = "[", mods = "CTRL" },
    }
    if config.keys then
      for _, injected in ipairs(wm_injected_keys) do
        for i = #config.keys, 1, -1 do
          local k = config.keys[i]
          if k.key == injected.key and k.mods == injected.mods then
            table.remove(config.keys, i)
          end
        end
      end
    end

    config.keys = config.keys or {}
    table.insert(config.keys, {
      key = "s",
      mods = "SUPER",
      action = wezterm.action_callback(function(win, pane)
        if keybindings.locked_mode then
          win:perform_action({ SendKey = { key = "s", mods = "SUPER" } }, pane)
          return
        end
        open_session_tree(win, pane)
      end),
    })

    wezterm.on("augment-command-palette", function(_window, _pane)
      return {
        {
          brief = "Session tree",
          action = wezterm.action_callback(function(win, pane)
            open_session_tree(win, pane)
          end),
        },
        {
          brief = "Switch seshy session / workspace",
          action = wm.workspace_switcher(),
        },
        {
          brief = "Switch to previous workspace",
          action = wm.switch_to_previous_workspace(),
        },
        {
          brief = "Next workspace",
          action = wezterm.action.SwitchWorkspaceRelative(1),
        },
        {
          brief = "Previous workspace",
          action = wezterm.action.SwitchWorkspaceRelative(-1),
        },
      }
    end)
  end

end

return M
