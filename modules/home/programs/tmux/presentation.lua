local json = require("dkjson")
local source, assets_file, deck, agents, classifier = table.unpack(arg)
local input = assert(json.decode(io.read("*a")))
local file = assert(io.open(assets_file, "r"))
local assets = assert(json.decode(file:read("*a")))
file:close()
package.path = source .. "/?.lua;" .. source .. "/?/init.lua;" .. package.path
package.loaded.wezterm = {
  nerdfonts = assets.nerdfonts,
  json_parse = json.decode,
  format = function(items)
    return items
  end,
}
package.loaded["sysinit.pkg.utils"] = {
  load_json_file = function()
    return assets.settings
  end,
  get_config_path = function()
    return "config.json"
  end,
}
local classify = assert(loadfile(classifier))("module")
local records = classify(input.snapshot, source, deck, agents, input.panes_dir, input.history_file)
local state = {}
for _, record in ipairs(records) do
  state[record.pane] = record
end
local format = require("sysinit.pkg.ui.format")
local panes = require("sysinit.pkg.ui.panes")
local badges = require("sysinit.pkg.ui.badges")
local badge_name, badge_color = badges.name, badges.color
local function badge_id(id)
  return assert(tonumber((tostring(id):gsub("^%%", ""))))
end
badges.name = function(id)
  return badge_name(badge_id(id))
end
badges.color = function(id, colors)
  return badge_color(badge_id(id), colors)
end
panes.latest = function(id)
  local rec = state["%" .. tostring(id)]
  return rec and rec.status
end
require("session_tree.options").configure({ adapters = { format = format, panes = panes, badges = badges } })
local ribbon = require("session_tree.ribbon")
local processes = {}
for name, entry in pairs(assets.processes) do
  processes[name] = entry
  for _, alias in ipairs(entry.aliases or {}) do
    processes[alias:lower()] = entry
  end
end
local sigil = {
  items = function(name, opts)
    local entry = processes[name:lower()]
    if not entry then
      return {}
    end
    local items = {}
    if entry.color then
      items[#items + 1] = { Foreground = { Color = entry.color } }
    end
    items[#items + 1] = { Text = entry.icon .. (opts.padding == "right" and " " or "") }
    if opts.reset then
      items[#items + 1] = "ResetAttributes"
    end
    return items
  end,
}
local colors = require("session_tree.session_tree").colors(nil, assets.settings)
local icons = {
  session = assets.symbols.Workspace or assets.nerdfonts.cod_briefcase,
  tab = assets.nerdfonts.md_tab,
  attn = assets.nerdfonts.md_alert,
}
local ctx = {
  ribbon = {
    new = function()
      local r = ribbon.new()
      r.items = r.format
      return r
    end,
  },
  sigil = sigil,
  sigil_ok = true,
  ribbon_ok = true,
  icons = icons,
  home = os.getenv("HOME") or "",
}
local workspaces, by_session, windows, by_window, ranks = {}, {}, {}, {}, panes.state_rank
local function token_text(items)
  if type(items) == "string" then
    return items
  end
  local text = {}
  for _, item in ipairs(items) do
    if type(item) == "table" and item.Text then
      text[#text + 1] = item.Text
    end
  end
  return table.concat(text)
end
for _, row in ipairs(input.panes) do
  if row.parent == "" then
    if not by_session[row.session] then
      local ws = {
        name = row.session,
        domain = "local",
        tabs = {},
        last_active = row.activity,
        window_count = 1,
        slot = #workspaces + 1,
        id = row.session_id,
      }
      workspaces[#workspaces + 1] = ws
      by_session[row.session] = ws
    end
    if not by_window[row.window] then
      local win = {
        tab_id = row.window,
        index = row.index + 1,
        domain = "local",
        title = row.window_name,
        first_row = row,
        active_pane_id = row.id,
        panes = {},
        session = row.session,
        active = row.window_active,
      }
      by_window[row.window] = win
      windows[#windows + 1] = win
      table.insert(by_session[row.session].tabs, win)
    end
  end
end
local pane_rows = {}
for _, row in ipairs(input.panes) do
  local ws = by_session[row.parent ~= "" and row.parent_name or row.session]
  if ws then
    local win = by_window[row.window]
    if row.parent ~= "" then
      for _, candidate in ipairs(ws.tabs) do
        if candidate.active then
          win = candidate
          break
        end
      end
      win = win or ws.tabs[1]
    end
    local rec = state[row.id] or {}
    local proc = row.process_name
    local domain = "local"
    for _, snap in ipairs(input.snapshot) do
      if snap.pane == row.id and snap.process then
        domain = snap.domain or "local"
        local info = snap.process
        while info.children and #info.children > 0 do
          info = info.children[#info.children]
        end
        proc = info.name or info.executable or proc
      end
    end
    proc = proc:match("([^/]+)$") or proc
    rec.pane_id = row.id
    rec.workspace = ws.name
    rec.domain = domain
    rec.title = rec.agent or proc
    rec.cwd = row.cwd
    rec.repo = rec.repo or ""
    rec.tab_title = win.title
    rec.rank = ranks[rec.status] or 0
    rec.reason = rec.reason or ""
    rec.floating = row.floating or row.parent ~= ""
    pane_rows[row.id] = rec
    table.insert(win.panes, rec)
    if row.pane_active then
      win.active_pane_id = row.id
      win.active_row = row
    end
    if rec.status and (not ws.rank or rec.rank > ws.rank) then
      ws.status = rec.status
      ws.rank = rec.rank
    end
  end
end
for _, ws in ipairs(workspaces) do
  local domain
  for _, win in ipairs(ws.tabs) do
    local pane_domain
    for _, rec in ipairs(win.panes) do
      if pane_domain == nil then
        pane_domain = rec.domain
      elseif pane_domain ~= rec.domain then
        pane_domain = false
      end
    end
    win.domain = pane_domain
    if domain == nil then
      domain = pane_domain
    elseif domain ~= pane_domain then
      domain = false
    end
  end
  ws.domain = domain
end
local tree = { workspaces = workspaces, attention = {} }
for _, rec in pairs(pane_rows) do
  if rec.rank >= ranks.working then
    table.insert(tree.attention, rec)
  end
end
local renderer = require("session_tree.tree_rows").new(ctx)
local function render(filter)
  local rows = renderer(tree, {}, filter, colors)
  for _, row in ipairs(rows) do
    local id = row.id:match("^pane:(.*)")
    if id and pane_rows[id].floating then
      row.label[#row.label + 1] = { Text = "  (floating)" }
    end
    row.text = token_text(row.label)
  end
  return rows
end
local sessions = {}
local statusbar = require("sysinit.pkg.ui.statusbar")
for _, ws in ipairs(workspaces) do
  local items = statusbar.session_chips({
    active_workspace = function()
      return ws.name
    end,
  }, { [ws.name] = { status = ws.status, names = {} } }, { [ws.name] = ws.slot }, colors, assets.tabs)
  local inactive = statusbar.session_chips({
    active_workspace = function()
      return ""
    end,
  }, { [ws.name] = { status = ws.status, names = {} } }, { [ws.name] = ws.slot }, colors, assets.tabs)
  local tail, head, inactive_head = {}, {}, {}
  for i, item in ipairs(items) do
    if i > #items - 4 then
      tail[#tail + 1] = item
    else
      head[#head + 1] = item
    end
  end
  for i = 1, #inactive - 4 do
    inactive_head[#inactive_head + 1] = inactive[i]
  end
  sessions[#sessions + 1] = {
    id = ws.id,
    name = ws.name,
    slot = ws.slot,
    items = head,
    inactive = inactive_head,
    tail = tail,
    tail_text = token_text(tail),
    text = token_text(items),
  }
end
package.path = assets.settings.plugins.tabline .. "/plugin/?.lua;" .. package.path
local function tab_sections(values)
  local result = {}
  for _, value in ipairs(values) do
    if value == "sysinit-tab-index" then
      value = statusbar.tab_index
    elseif type(value) == "table" and value.component then
      value[1], value.component = value.component, nil
    end
    result[#result + 1] = value
  end
  return result
end
package.loaded["tabline.config"] = {
  component_opts = assets.components,
  theme = assets.theme,
  opts = { options = { tabs_enabled = true, tab_separators = { left = "", right = "" } } },
  sections = {
    tab_active = tab_sections(assets.tab_sections.active),
    tab_inactive = tab_sections(assets.tab_sections.inactive),
  },
}
local tabline_tabs = require("tabline.tabs")
local tabline_util = require("tabline.util")
local host_component = require("tabline.components.window.domain")
local hosts = { local_domain = 1 }
local host_names = {}
for _, rec in pairs(pane_rows) do
  if rec.domain ~= "local" then
    host_names[rec.domain] = true
  end
end
local ordered_hosts = {}
for name in pairs(host_names) do
  ordered_hosts[#ordered_hosts + 1] = name
end
table.sort(ordered_hosts)
for i, name in ipairs(ordered_hosts) do
  hosts[name] = i + 1
end
local labels = {}
for _, win in ipairs(windows) do
  local row = win.active_row or win.first_row
  local rec = pane_rows[row.id]
  local tab = {
    tab_id = win.tab_id,
    tab_index = win.index - 1,
    is_active = win.active,
    active_pane = { current_working_dir = { file_path = row.cwd }, is_zoomed = row.zoomed },
  }
  local items = tabline_tabs.set_title(tab, false)
  local status, rank
  for _, pane in ipairs(win.panes) do
    if pane.status and (not rank or pane.rank > rank) then
      status, rank = pane.status, pane.rank
    end
  end
  local tail = {}
  if status and status ~= "idle" then
    tail = {
      { Foreground = { Color = format.status_color(status, colors) } },
      { Text = (format.state_icons[status] or "") .. " " },
    }
  end
  local domain = rec.domain
  local opts = tabline_util.deep_extend(tabline_util.deep_copy(assets.components), assets.domain_options)
  opts.padding = { left = 0, right = 1 }
  local name = host_component.update({
    active_pane = function()
      return {
        get_domain_name = function()
          return domain
        end,
      }
    end,
  }, opts)
  local host_items = { { Text = "[" .. tostring(domain == "local" and 1 or hosts[domain]) .. "] " } }
  for _, item in ipairs(tabline_util.create_component(name, opts, tab, {})) do
    host_items[#host_items + 1] = item
  end
  labels[#labels + 1] = {
    id = win.tab_id,
    session = win.session,
    index = win.index - 1,
    items = items,
    text = token_text(items) .. token_text(tail),
    tail = tail,
    tail_text = token_text(tail),
    active = win.active,
    host = host_items,
    host_text = token_text(host_items),
  }
end
local result = {
  rows = render("all"),
  agents = render("agents"),
  attention = render("blocked"),
  sessions = sessions,
  windows = labels,
  tabs = assets.tabs,
  icons = assets.mode_icons,
  mode = assets.theme.normal_mode.a,
  copy_mode = assets.theme.copy_mode.a,
  host = assets.theme.normal_mode.z or assets.theme.normal_mode.a,
  center = assets.theme.normal_mode.c,
}
io.write(json.encode(result))
