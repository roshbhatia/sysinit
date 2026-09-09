local ui_badges = require("sysinit.pkg.ui.badges")
local ui_format = require("sysinit.pkg.ui.format")
local ui_panes = require("sysinit.pkg.ui.panes")
local M = {}

function M.new(ctx)
  local function append_host(r, colors, host, is_local, stale)
    r:append(nil, (is_local or stale) and colors.chrome or colors.dir_ic, "@" .. (host or "localhost"))
    r:append(nil, colors.chrome, " ")
  end

  -- A live node's host is its panes' domain; false means they disagree, and
  -- no tag is drawn.
  local function append_domain(r, colors, domain, stale)
    if domain == false then
      return
    end
    local host, is_local = ui_format.domain_host(domain)
    append_host(r, colors, host, is_local, stale)
  end

  local function attn_row(rec, now, colors)
    local sc = ui_format.status_color(rec.status, colors) or colors.idle
    local icon = ui_format.state_icons[rec.status] or "●"
    local is_urgent = rec.rank and rec.rank >= ui_panes.state_rank.working
    local age = rec.since and ui_format.age(now - rec.since) or ""

    local r = ctx.ribbon.new("attn")
    if is_urgent then
      r:append(nil, colors.waiting, ctx.icons.attn .. " ")
    else
      r:append(nil, nil, "  ")
    end
    r:append(nil, sc, icon .. " ")
    append_domain(r, colors, rec.domain)
    local crumb = rec.workspace
    if rec.tab_title ~= "" then
      crumb = crumb .. " · " .. rec.tab_title
    end
    r:append(nil, colors.name, crumb, "Bold")
    local attn_dp = ui_format.smart_path(rec.cwd)
    if attn_dp == "" then
      attn_dp = rec.repo
    end
    if attn_dp ~= "" and attn_dp ~= rec.tab_title then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "at ")
      r:append(nil, colors.name, attn_dp)
    end
    local scope = ui_format.scope_label(rec)
    if scope then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "on ")
      r:append(nil, colors.age, scope)
      if rec.dirty then
        r:append(nil, colors.working, " *")
      end
    end
    if rec.title ~= "" then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, colors.age, "in ")
      if ctx.sigil_ok then
        local proc_items = ctx.sigil.items(rec.title, { fallback = true, padding = "right", reset = true })
        r:append_items(proc_items)
      end
      r:append(nil, colors.name, rec.title)
    end
    local fmt = ui_format.status_label(rec.status, rec.reason)
    if fmt ~= "" then
      r:append(nil, colors.reason, "  " .. fmt)
    end
    if age ~= "" then
      r:append(nil, colors.age, "  " .. age)
    end
    local bc = ui_badges.color(rec.pane_id, colors)
    if bc then
      r:append(nil, colors.chrome, "  ")
      r:append(nil, bc, ui_badges.name(rec.pane_id))
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
        for _, rec in ipairs(tree.attention) do
          list[#list + 1] = rec
        end
      else
        for _, ws in ipairs(tree.workspaces) do
          for _, tnode in ipairs(ws.tabs) do
            for _, rec in ipairs(tnode.panes) do
              if rec.status then
                list[#list + 1] = rec
              end
            end
          end
        end
        table.sort(list, function(a, b)
          if a.rank ~= b.rank then
            return a.rank > b.rank
          end
          return (a.since or now) < (b.since or now)
        end)
      end
      for _, rec in ipairs(list) do
        add("pane:" .. rec.pane_id, attn_row(rec, now, colors), rec)
      end
      return choices
    end

    if filter == "sessions" then
      local live = {}
      for _, ws in ipairs(tree.workspaces) do
        if not ws.dormant then
          live[#live + 1] = ws
        end
      end
      table.sort(live, function(a, b)
        if (a.last_active or 0) ~= (b.last_active or 0) then
          return (a.last_active or 0) > (b.last_active or 0)
        end
        return a.name < b.name
      end)
      for i, ws in ipairs(live) do
        local sc = ui_format.status_color(ws.status, colors)
        local qs = i <= 9 and tostring(i) or string.char(96 + i - 9)
        local r = ctx.ribbon.new("ws")
        r:append(nil, colors.chrome, qs .. "  ")
        r:append(nil, sc or colors.ws_live, ctx.icons.session .. " ")
        append_domain(r, colors, ws.domain, ws.stale)
        r:append(nil, colors.name, ws.display_name or ws.name, "Bold")
        if ws.status then
          r:append(nil, sc or colors.working, "  " .. (ui_format.state_icons[ws.status] or "●"))
        end
        local age = ws.last_active and ui_format.age(now - ws.last_active) or ""
        if age ~= "" then
          r:append(nil, colors.age, "  " .. age)
        end
        add("ws:" .. ws.name, r:format(), { workspace = ws.name, dormant = false })
      end
      return choices
    end

    local live_sorted = {}
    for _, ws in ipairs(tree.workspaces) do
      if not ws.dormant then
        live_sorted[#live_sorted + 1] = ws
      end
    end
    table.sort(live_sorted, function(a, b)
      if (a.last_active or 0) ~= (b.last_active or 0) then
        return (a.last_active or 0) > (b.last_active or 0)
      end
      return a.name < b.name
    end)

    for _, ws in ipairs(live_sorted) do
      local sc = ui_format.status_color(ws.status, colors)
      local ws_r = ctx.ribbon.new("ws")
      ws_r:append(nil, sc or colors.ws_live, ctx.icons.session .. " ")
      append_domain(ws_r, colors, ws.domain, ws.stale)
      ws_r:append(nil, colors.name, ws.display_name or ws.name, { "Bold", "Single" })
      if ws.status then
        local ws_lbl = ui_format.state_labels[ws.status] or ""
        ws_r:append(nil, colors.chrome, "  ")
        ws_r:append(nil, sc or colors.working, ui_format.state_icons[ws.status] or "●")
        if ws_lbl ~= "" then
          ws_r:append(nil, colors.reason, " " .. ws_lbl)
        end
      end
      add("ws:" .. ws.name, ws_r:format(), { workspace = ws.name, dormant = false })

      for ti, tnode in ipairs(ws.tabs) do
        local tlast = ti == #ws.tabs
        local tbranch = tlast and "  └─ " or "  ├─ "
        local tab_r = ctx.ribbon.new("tab")
        tab_r:append(nil, colors.chrome, tbranch)
        tab_r:append(nil, colors.ws_live, ctx.icons.tab)
        -- tnode.index is the tab's number inside its own window, which is the
        -- number ActivateTab answers to. A workspace with two windows also needs
        -- the window said out loud, or two rows both read [1].
        local tab_ref = tostring(tnode.index)
        if (ws.window_count or 1) > 1 then
          tab_ref = "w" .. tostring(tnode.window_index) .. ":" .. tab_ref
        end
        tab_r:append(nil, colors.chrome, " [" .. tab_ref .. "]")
        tab_r:append(nil, colors.chrome, "  ")
        append_domain(tab_r, colors, tnode.domain)
        tab_r:append(nil, colors.name, tnode.title)
        add(
          "tab:" .. tnode.tab_id,
          tab_r:format(),
          { pane_id = tnode.active_pane_id, workspace = ws.name, tab_index = tab_ref }
        )

        for pi, rec in ipairs(tnode.panes) do
          local pbranch = (tlast and "     " or "  │  ") .. (pi == #tnode.panes and "└─ " or "├─ ")
          local pane_r = ctx.ribbon.new("pane")
          pane_r:append(nil, colors.chrome, pbranch)
          local bc = ui_badges.color(rec.pane_id, colors)
          if bc then
            pane_r:append(nil, colors.chrome, "<")
            pane_r:append(nil, bc, ui_badges.name(rec.pane_id))
            pane_r:append(nil, colors.chrome, "> ")
          end
          append_domain(pane_r, colors, rec.domain)
          local pane_dp = ui_format.smart_path(rec.cwd)
          if pane_dp == "" then
            pane_dp = rec.repo
          end
          if pane_dp ~= "" then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "at ")
            pane_r:append(nil, colors.name, pane_dp)
          end
          local pane_scope = ui_format.scope_label(rec)
          if pane_scope then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "on ")
            pane_r:append(nil, colors.age, pane_scope)
            if rec.dirty then
              pane_r:append(nil, colors.working, " *")
            end
          end
          local proc = rec.title ~= "" and rec.title or nil
          if proc then
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, colors.age, "in ")
            if ctx.sigil_ok then
              local proc_items = ctx.sigil.items(proc, { fallback = true, padding = "right", reset = true })
              pane_r:append_items(proc_items)
            end
            pane_r:append(nil, colors.name, proc)
          end
          if rec.status then
            local asc = ui_format.status_color(rec.status, colors) or colors.idle
            local p_fmt = ui_format.status_label(rec.status, rec.reason)
            pane_r:append(nil, colors.chrome, "  ")
            pane_r:append(nil, asc, ui_format.state_icons[rec.status] or "●")
            if p_fmt ~= "" then
              pane_r:append(nil, colors.reason, " " .. p_fmt)
            end
            if rec.status ~= "done" then
              local age = rec.since and ui_format.age(now - rec.since) or ""
              if age ~= "" then
                pane_r:append(nil, colors.age, " " .. age)
              end
            end
          end
          add("pane:" .. rec.pane_id, pane_r:format(), rec)
        end
      end
    end

    return choices
  end

  return session_tree_choices
end

return M
