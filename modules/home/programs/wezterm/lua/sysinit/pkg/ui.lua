local wezterm = require("wezterm")

local keybindings = require("sysinit.pkg.keybindings")
local utils = require("sysinit.pkg.utils")
local plugin_loader = require("sysinit.pkg.plugin_loader")

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
  local agent_state_icons = {
    waiting = nf.md_clock_alert or "⏱",
    done    = nf.md_check_circle or "✔",
    working = nf.md_loading or "⟳",
    idle    = nf.cod_circle_small_filled or "○",
  }
  local agent_state_rank = {
    waiting = 4,
    done    = 3,
    working = 2,
    idle    = 1,
  }
  local agent_state_labels = {
    waiting = "Needs Input",
    done    = "Done",
    working = "Working",
    idle    = "",
  }
  local SUPPRESSED_REASONS = { ["your move"] = true, ["submit"] = true, ["message"] = true }

  local function status_color(status, colors)
    if status == "waiting" then return colors.waiting
    elseif status == "done" then return colors.done
    elseif status == "working" then return colors.working
    end
    return nil
  end

  local function format_status_label(status, reason)
    local lbl = agent_state_labels[status] or ""
    local show_reason = reason and reason ~= "" and not SUPPRESSED_REASONS[reason]
    if lbl == "" and not show_reason then return "" end
    local parts = {}
    if lbl ~= "" then parts[#parts + 1] = lbl end
    if show_reason then parts[#parts + 1] = reason end
    return table.concat(parts, " · ")
  end

  local function format_age(secs)
    if not secs or secs < 0 then
      return ""
    end
    if secs < 60 then
      return string.format("%ds", secs)
    elseif secs < 3600 then
      return string.format("%dm", math.floor(secs / 60))
    end
    return string.format("%dh", math.floor(secs / 3600))
  end

  local function pane_repo(p)
    local ok, repo, cwd = pcall(function()
      local url = p:get_current_working_dir()
      if not url then return "", "" end
      local path
      if type(url) == "string" then
        path = url:gsub("^file://[^/]*", "")
      else
        path = url.file_path
      end
      if not path or path == "" then return "", "" end
      path = path:gsub("/+$", "")
      return path:match("([^/]+)$") or "", path
    end)
    if not ok then return "", "" end
    return repo or "", cwd or ""
  end

  -- Reads the pane record file for `branch` and `dirty`, which the OSC user
  -- variable does not carry. Schema: pkgs/sysinit-agent/internal/agentstate/SCHEMA.md.
  --
  -- The liveness rule is pane existence, and the caller already satisfies it:
  -- every id reaching here comes from `tab:panes_with_info()`, so a record whose
  -- pane is gone is a record nothing asks for. The record's `mux` marker is not
  -- checked, because the GUI process carries no `WEZTERM_UNIX_SOCKET` and so
  -- cannot tell which mux it is. `agent-state` deletes dead muxes' records
  -- instead.
  local function read_pane_git(pane_id)
    local path = utils.state_path("agentPanes", "agents/panes") .. "/" .. tostring(pane_id) .. ".json"
    local f = io.open(path, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(wezterm.json_parse, content)
    if not ok or type(data) ~= "table" then return nil end
    return {
      branch = type(data.branch) == "string" and data.branch ~= "" and data.branch or nil,
      dirty  = data.dirty == true,
    }
  end

  local function smart_path(full_cwd)
    if not full_cwd or full_cwd == "" then return "" end
    local home = os.getenv("HOME") or ""
    local seshy_base = utils.state_path("seshySessions", "seshy/sessions")
    if full_cwd == seshy_base or full_cwd:sub(1, #seshy_base + 1) == seshy_base .. "/" then
      local after = full_cwd:sub(#seshy_base + 2)  -- "<session>[/rest]"
      return after ~= "" and ("{sy}/" .. after) or "{sy}"
    end
    local gh_base = home .. "/github/"
    if full_cwd:sub(1, #gh_base) == gh_base then
      local rest = full_cwd:sub(#gh_base + 1)             -- "<tier>/<org>/<repo>[/sub]"
      local short = rest:match("^[^/]+/[^/]+/(.+)$") or rest
      return "{gh}/" .. short
    end
    if full_cwd == home then return "{home}" end
    if full_cwd:sub(1, #home + 1) == home .. "/" then
      return "{home}/" .. full_cwd:sub(#home + 2)
    end
    return full_cwd
  end

  -- Reads the OSC user variable, which wezterm has already base64-decoded,
  -- and falls back to the agent-deck plugin. Schema: pkgs/sysinit-agent/internal/agentstate/SCHEMA.md.
  -- The variable is authoritative here because it is live and dies with the
  -- pane, so it needs no liveness rule.
  local function pane_agent_state(p, deck_states)
    local status, reason, since, agent
    local uv = p:get_user_vars()
    local raw = uv and uv.agent_state
    if raw and raw ~= "" then
      local s, r, ts, a = raw:match("^([^|]*)|([^|]*)|([^|]*)|(.*)$")
      if s and agent_state_rank[s] then
        status, reason, since, agent = s, r, tonumber(ts), a
      end
    end
    if not status then
      local deck = deck_states[p:pane_id()]
      if deck and agent_state_rank[deck.status] then
        status = deck.status -- working | waiting | idle; no reason/age
        agent = deck.agent
      end
    end
    return status, reason, since, agent
  end

  local function compute_agent_session_states()
    local sessions = {}
    local panes = {}
    local deck_states = agent_deck_ok and agent_deck.get_all_agent_states() or {}

    local ok = pcall(function()
      for _, win in ipairs(wezterm.mux.all_windows()) do
        local workspace = win:get_workspace()
        local window_id = win:window_id()
        for _, tab in ipairs(win:tabs()) do
          local tab_id = tab:tab_id()
          for _, p in ipairs(tab:panes()) do
            local status, reason, since, agent = pane_agent_state(p, deck_states)
            if status then
              local rank = agent_state_rank[status]
              panes[#panes + 1] = {
                pane_id = p:pane_id(),
                window_id = window_id,
                tab_id = tab_id,
                workspace = workspace,
                repo = (function() local r, _ = pane_repo(p); return r end)(),
                branch = "", -- not in-memory; the state-file bus carries it
                agent = agent or "",
                status = status,
                reason = reason or "",
                since = since,
                rank = rank,
              }
              local cur = sessions[workspace]
              local replace = false
              if not cur or rank > cur.rank then
                replace = true
              elseif rank == cur.rank then
                local a, b = since, cur.since
                if a and (not b or a < b) then
                  replace = true
                end
              end
              if replace then
                sessions[workspace] = {
                  status = status,
                  reason = reason or "",
                  since = since,
                  rank = rank,
                }
              end
            end
          end
        end
      end
    end)
    if not ok then
      return {}, {}
    end
    return sessions, panes
  end

  local rollup_cache = { at = -1, sessions = {}, panes = {} }
  local function agent_session_states()
    local now = os.time()
    if now ~= rollup_cache.at then
      local sessions, panes = compute_agent_session_states()
      rollup_cache = { at = now, sessions = sessions, panes = panes }
    end
    return rollup_cache.sessions, rollup_cache.panes
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

  local function normalize_proc(raw)
    if not raw or raw == "" then return raw end
    return (raw:gsub("^%.", ""):gsub("%-wrapped$", ""))
  end

  local function pane_proc(p, agent)
    local ok, proc_name = pcall(function()
      local proc = p:get_foreground_process_name()
      if proc and proc ~= "" then
        return normalize_proc((proc:gsub("/+$", "")):match("([^/]+)$") or "")
      end
      return nil
    end)
    if ok and proc_name and proc_name ~= "" then
      return proc_name
    end
    if agent and agent ~= "" then
      return agent
    end
    local ok2, title = pcall(function() return normalize_proc(p:get_title() or "") end)
    return (ok2 and title) or ""
  end

  local function tab_label(tab, index, active_pane)
    local ok, title = pcall(function()
      return tab:get_title() or ""
    end)
    if ok and title and title ~= "" then
      return title
    end
    if active_pane then
      local proc = pane_proc(active_pane, nil)
      if proc ~= "" then
        return proc
      end
    end
    return "tab " .. tostring(index)
  end

  local function seshy_session_names(sy_bin)
    if not sy_bin or sy_bin == "" then
      return {}, false
    end
    local names = {}
    local ok, out = pcall(function()
      local success, stdout = wezterm.run_child_process({ sy_bin, "list" })
      if not success then
        error("sy list failed")
      end
      return stdout
    end)
    if not ok or not out then
      return {}, false
    end
    local first = true
    for _, line in ipairs(wezterm.split_by_newlines(out)) do
      if first then
        first = false
      elseif line ~= "" then
        local name = line:match("^(%S+)")
        if name then
          names[#names + 1] = name
        end
      end
    end
    return names, true
  end

  local home = os.getenv("HOME") or ""
  local seshy_dir = utils.state_path("seshySessions", "seshy/sessions")
  local sy_bin = home .. "/.local/bin/sy"
  do
    local env = utils.load_json_file(utils.get_config_path("env.json"))
    for dir in (env and env.PATH or ""):gmatch("[^:]+") do
      local candidate = dir .. "/sy"
      local fh = io.open(candidate, "r")
      if fh then
        fh:close()
        sy_bin = candidate
        break
      end
    end
  end

  local seshy_cache = { at = -1, names = {} }
  local function seshy_names_cached()
    local now = os.time()
    if now - seshy_cache.at >= 5 then
      local names, ok = seshy_session_names(sy_bin)
      if ok then
        seshy_cache = { at = now, names = names }
      else
        seshy_cache.at = now
      end
    end
    return seshy_cache.names
  end

  local function active_session_names()
    local seen, names = {}, {}
    pcall(function()
      for _, win in ipairs(wezterm.mux.all_windows()) do
        local n = win:get_workspace()
        if n and n ~= "" and not seen[n] then
          seen[n] = true
          names[#names + 1] = n
        end
      end
    end)
    return names
  end

  local DEFAULT_WORKSPACE = "default"
  local DEFAULT_SLOT = 1
  local MAX_SLOT = 9

  local function compute_session_slots()
    local prev = wezterm.GLOBAL.workspace_slots
    if type(prev) ~= "table" then
      prev = {}
    end

    local names = active_session_names()
    if #names == 0 then
      return prev
    end

    local present = {}
    for _, n in ipairs(names) do
      present[n] = true
    end

    local slots, taken = {}, {}
    taken[DEFAULT_SLOT] = true
    for name, slot in pairs(prev) do
      if
        present[name]
        and name ~= DEFAULT_WORKSPACE
        and type(slot) == "number"
        and not taken[slot]
      then
        slots[name] = slot
        taken[slot] = true
      end
    end

    local fresh = {}
    for _, n in ipairs(names) do
      if n ~= DEFAULT_WORKSPACE and not slots[n] then
        fresh[#fresh + 1] = n
      end
    end
    table.sort(fresh)
    local probe = 1
    for _, name in ipairs(fresh) do
      while probe <= MAX_SLOT and taken[probe] do
        probe = probe + 1
      end
      if probe > MAX_SLOT then
        break
      end
      slots[name] = probe
      taken[probe] = true
    end

    slots[DEFAULT_WORKSPACE] = DEFAULT_SLOT

    local changed = false
    for name, slot in pairs(slots) do
      if prev[name] ~= slot then
        changed = true
        break
      end
    end
    if not changed then
      for name in pairs(prev) do
        if slots[name] == nil then
          changed = true
          break
        end
      end
    end
    if changed then
      wezterm.GLOBAL.workspace_slots = slots
    end
    return slots
  end

  local slots_cache = { at = -1, slots = {} }
  local function session_slots()
    local now = os.time()
    if now ~= slots_cache.at then
      slots_cache = { at = now, slots = compute_session_slots() }
    end
    return slots_cache.slots
  end

  local touch_throttle = {}
  local function touch_workspace(name)
    if not name or name == "" then
      return
    end
    local now = os.time()
    if touch_throttle[name] and now - touch_throttle[name] < 5 then
      return
    end
    touch_throttle[name] = now
    local t = wezterm.GLOBAL.workspace_last_active or {}
    t[name] = now
    wezterm.GLOBAL.workspace_last_active = t
  end

  local function workspace_last_active(name)
    local t = wezterm.GLOBAL.workspace_last_active
    return type(t) == "table" and t[name] or nil
  end

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
    local deck_states = agent_deck_ok and agent_deck.get_all_agent_states() or {}
    local workspaces = {}
    local ws_index = {}
    local attention = {}

    pcall(function()
      for _, win in ipairs(wezterm.mux.all_windows()) do
        local workspace = win:get_workspace()
        local window_id = win:window_id()
        local ws = ws_index[workspace]
        if not ws then
          ws = {
            name = workspace,
            dormant = false,
            rank = 0,
            since = nil,
            last_active = workspace_last_active(workspace),
            status = nil,
            tabs = {},
          }
          ws_index[workspace] = ws
          workspaces[#workspaces + 1] = ws
        end
        for ti, tab in ipairs(win:tabs()) do
          local infos = tab:panes_with_info()
          local active_pane
          for _, info in ipairs(infos) do
            if info.is_active then
              active_pane = info.pane
            end
          end
          local resolved_active = active_pane or (infos[1] and infos[1].pane)
          local tnode = {
            tab_id = tab:tab_id(),
            index = ti,
            title = tab_label(tab, ti, resolved_active),
            active_pane_id = resolved_active and resolved_active:pane_id() or nil,
            panes = {},
          }
          for _, info in ipairs(infos) do
            local p = info.pane
            local status, reason, since, agent = pane_agent_state(p, deck_states)
            local rank = status and agent_state_rank[status] or 0
            local pid = p:pane_id()
            local repo, cwd = pane_repo(p)
            local git = read_pane_git(pid)
            local rec = {
              pane_id = pid,
              window_id = window_id,
              tab_id = tnode.tab_id,
              workspace = workspace,
              tab_title = tnode.title,
              repo = repo,
              cwd = cwd,
              branch = git and git.branch or nil,
              dirty = git and git.dirty or false,
              title = pane_proc(p, agent),
              agent = agent or "",
              status = status,
              reason = reason or "",
              since = since,
              rank = rank,
            }
            tnode.panes[#tnode.panes + 1] = rec
            if since and (not ws.last_active or since > ws.last_active) then
              ws.last_active = since
            end
            if rank >= agent_state_rank.working then
              attention[#attention + 1] = rec
              if rank > ws.rank or (rank == ws.rank and since and (not ws.since or since < ws.since)) then
                ws.rank, ws.since, ws.status = rank, since, status
              end
            end
          end
          ws.tabs[#ws.tabs + 1] = tnode
        end
      end
    end)

    for _, name in ipairs(seshy_names_cached()) do
      if not ws_index[name] then
        local ws = { name = name, dormant = true, rank = 0, since = nil, status = nil, tabs = {} }
        ws_index[name] = ws
        workspaces[#workspaces + 1] = ws
      end
    end

    local now = os.time()
    table.sort(attention, function(a, b)
      if a.rank ~= b.rank then
        return a.rank > b.rank
      end
      return (a.since or now) < (b.since or now)
    end)

    return { workspaces = workspaces, attention = attention }
  end

  local function tree_colors(win)
    local ok, pal = pcall(function()
      return win:effective_config().resolved_palette
    end)
    pal = (ok and pal) or (config_data and config_data.colors) or {}
    local a, b = pal.ansi or {}, pal.brights or {}
    return {
      ws_live  = b[7] or b[8] or pal.foreground or "#c0caf5",   -- bright cyan/white — live session
      ws_dorm  = a[8] or pal.foreground or "#a9b1d6",           -- ansi-white (mid-gray) — dormant
      dir_ic   = a[5] or "#7aa2f7",                             -- ansi blue — folder icon (softer than bright)
      waiting  = b[2] or a[2] or "#f7768e",                     -- bright red — needs input (status signal: keep vivid)
      done     = b[3] or a[3] or "#9ece6a",                     -- bright green — finished (status signal: keep vivid)
      working  = b[4] or a[4] or "#e0af68",                     -- bright yellow — running (status signal: keep vivid)
      idle     = a[8] or "#a9b1d6",                             -- ansi-white (mid-gray) — idle
      name     = pal.foreground or "#c0caf5",
      reason   = a[6] or "#bb9af7",                             -- ansi magenta — muted; reason is secondary info
      age      = a[8] or "#a9b1d6",                             -- ansi-white (mid-gray) — timestamps
      chrome   = b[1] or "#414868",                             -- bright-black — intentionally dim tree lines
      badge_bg = pal.cursor_bg or b[1] or "#414868",            -- subtle chip background for pane badges
      ghost    = a[8] or pal.foreground or "#a9b1d6",            -- muted bracketed match suffix
      ansi     = a,                                              -- raw ansi array for badge color slots
      brights  = b,
    }
  end

  local function agent_status()
    local sessions = agent_session_states()
    local now = os.time()
    local best, count = nil, 0
    for _, st in pairs(sessions) do
      if st.rank >= agent_state_rank.working then
        count = count + 1
        if
          not best
          or st.rank > best.rank
          or (st.rank == best.rank and (st.since or now) < (best.since or now))
        then
          best = st
        end
      end
    end
    if not best then
      return ""
    end
    local icon = agent_state_icons[best.status] or "●"
    local text = " " .. icon
    if count > 1 then
      text = text .. " " .. count
    end
    return wezterm.format({ { Text = text .. " " } })
  end

  local CHIP_NAME_MAX = 16

  local function session_chips(window)
    local slots = session_slots()
    local ordered = {}
    for name, slot in pairs(slots) do
      ordered[#ordered + 1] = { name = name, slot = slot }
    end
    if #ordered == 0 then
      return ""
    end
    table.sort(ordered, function(a, b)
      return a.slot < b.slot
    end)

    local sessions = agent_session_states()
    local active = ""
    pcall(function()
      active = window:active_workspace()
    end)
    local colors = tree_colors(window)

    local items = {}
    for _, entry in ipairs(ordered) do
      local st = sessions[entry.name]
      local status = st and st.status or nil
      local is_active = entry.name == active
      local label = entry.name
      if #label > CHIP_NAME_MAX then
        label = label:sub(1, CHIP_NAME_MAX - 1) .. "…"
      end
      local rank = status and agent_state_rank[status] or 0
      local needs_attention = rank >= agent_state_rank.done
      local sc = status_color(status, colors) or colors.idle
      local fg
      if needs_attention then
        fg = sc
      elseif is_active then
        fg = colors.name
      else
        fg = colors.chrome
      end
      items[#items + 1] = { Attribute = { Underline = is_active and "Single" or "None" } }
      items[#items + 1] = { Attribute = { Intensity = (is_active or needs_attention) and "Bold" or "Normal" } }
      items[#items + 1] = { Foreground = { Color = fg } }
      items[#items + 1] = { Text = "  " .. tostring(entry.slot) .. " " }
      items[#items + 1] = { Foreground = { Color = sc } }
      items[#items + 1] = { Text = status and (agent_state_icons[status] or "●") or "·" }
      items[#items + 1] = { Foreground = { Color = fg } }
      items[#items + 1] = { Text = " " .. label }
    end
    items[#items + 1] = { Text = " " }
    return wezterm.format(items)
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

  local BADGE_NAMES = {
    "muadib",   "stilgar",  "chani",    "gurney",   "feyd",     "irulan",
    "alia",     "thufir",   "mentat",   "kwisatz",  "hayt",     "korba",    "scytale",
    "shrike",   "kassad",   "silenus",  "brawne",   "aenea",    "raul",
    "consul",   "ummon",    "moneta",   "sol",      "endymion", "templar",
    "aragorn",  "gandalf",  "samwise",  "legolas",  "gimli",    "boromir",
    "faramir",  "eowyn",    "galadriel","elrond",   "saruman",  "theoden",
    "frodo",    "merry",    "pippin",   "glorfindel","haldir",
    "kaladin",  "dalinar",  "szeth",    "jasnah",   "shallan",  "adolin",
    "wit",      "vin",      "elend",    "kelsier",  "sazed",    "spook",
    "breeze",   "marsh",    "nightblood","hoid",    "vasher",   "renarin",
    "lift",     "taravangian","navani",
    "hadrian",  "valka",    "pallino",  "lorian",   "bassander",
    "vorgossos","gibson",   "siran",    "elara",    "kharn",
    "logen",    "glokta",   "jezal",    "bayaz",    "ferro",    "dogman",
    "shivers",  "monza",    "cosca",    "friendly", "temple",   "caul",     "chella",
    "kvothe",   "denna",    "bast",     "auri",     "elodin",   "kilvin",
    "simmon",   "wilem",    "devi",     "tempi",    "felurian", "ambrose",
    "case",     "molly",    "wintermute","armitage", "riviera",  "maelcum",  "flatline",
    "darrow",   "sevro",    "mustang",  "cassius",  "roque",    "victra",   "lysander",
    "severian", "thecla",   "dorcas",   "agia",     "baldanders","typhon",  "jonas",
    "jorg",     "makin",    "rike",     "sageous",  "miana",    "coddin",   "jalan",    "snorri",
    "maia",     "csevet",   "cala",     "beshelar", "setheris",
    "keogh",    "dragosani","zek",      "nathan",
    "alwyn",    "evadine",  "deckin",   "tiler",
    "vaelin",   "reva",     "nortah",   "caenis",   "barkus",
    "vis",      "emissa",   "callidus", "acqua",    "ulciscor",
    "eragon",   "saphira",  "arya",     "murtagh",  "brom",     "nasuada",  "roran",    "oromis",   "galbatorix",
    "kinch",    "galva",    "norrigal",
    "thomas",
    "ripley",   "newt",     "bishop",   "hicks",    "ash",      "hudson",   "vasquez",  "dallas",   "lambert",  "burke",
    "dutch",    "mac",      "blain",    "harrigan", "dillon",
    "deckard",  "rachael",  "roy",      "pris",     "gaff",     "joi",      "luv",
    "snake",    "otacon",   "meryl",    "liquid",   "ocelot",   "raiden",   "solidus",  "vamp",     "mantis",   "wolf",
    "quiet",    "paz",      "skull",
    "leon",     "claire",   "jill",     "wesker",   "ada",      "barry",    "chris",    "ethan",    "heisenberg",
    "dimitrescu",
  }

  local function pane_badge(pane_id)
    local h = pane_id * 2654435761  -- Knuth multiplicative hash
    return BADGE_NAMES[(h % #BADGE_NAMES) + 1]
  end

  local function pane_badge_color(pane_id, colors)
    local h = pane_id * 2654435761
    local slot = (h % 6) + 2  -- ansi slots 2..7
    if type(colors) == "table" then
      local a = colors.ansi or (colors.colors and colors.colors.ansi)
      if type(a) == "table" and a[slot] then return a[slot] end
      local b = colors.brights or colors
      if type(b) == "table" then return b[(h % 6) + 2] end
    end
    return nil
  end

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
