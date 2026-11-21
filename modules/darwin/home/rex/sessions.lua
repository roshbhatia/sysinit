return function(settings, layout)
  local action = "sysinit_switch_session"

  local function call_provider(provider, capability, id)
    local argv = { unpack(settings.picker.command) }
    argv[#argv + 1] = provider.manifest
    argv[#argv + 1] = capability
    argv[#argv + 1] = id
    local result = assert(rex.exec(argv, { env = { PATH = settings.path }, timeout = 6 }))
    if not result.ok then
      error(result.stderr ~= "" and result.stderr or ("Provider failed: " .. provider.name))
    end
    return assert(rex.json.decode(result.stdout))
  end

  local function open_provider(provider, sessions)
    local listed = call_provider(provider, "picker.list")
    local items = {}
    for _, item in ipairs(listed.items or {}) do
      local details = {}
      for index = 2, #item.segments do
        details[#details + 1] = item.segments[index].text
      end
      items[#items + 1] = {
        id = item.id,
        title = item.segments[1].text,
        subtitle = table.concat(details, " "),
      }
    end
    if #items == 0 then
      error("No entries from " .. provider.name)
    end

    local id = rex.ui.pick({ title = provider.name, placeholder = "Filter entries", items = items })
    if not id then
      return
    end
    local plan = call_provider(provider, "picker.open", id)
    if plan.kind ~= "spawn" then
      error("Unsupported launch plan from " .. provider.name)
    end

    if provider.name == "tq" then
      assert(
        rex.session.new_window({ layout = layout(plan), window_label = plan.label, focus = true })
      )
      return
    end
    local label = provider.name .. ": " .. plan.label
    if provider.name == "seshy" then
      for _, session in ipairs(sessions) do
        if session.label == label then
          rex.client.queue("session.select", { session_id = session.session_id })
          return
        end
      end
    end
    local created = assert(rex.call("session.create", {
      label = label,
      initial_windows = { { layout = layout(plan) } },
    }))
    rex.client.queue("session.select", { session_id = created.session_id })
  end

  rex.action({
    name = action,
    title = "Switch session",
    run = function()
      local sessions = assert(rex.call("session.list", {})).sessions
      local providers = {}
      local items = {}
      for _, provider in ipairs(settings.picker.providers) do
        local id = "provider:" .. provider.name
        providers[id] = provider
        items[#items + 1] =
          { id = id, title = provider.key .. "  " .. provider.name, icon = "folder" }
      end
      for _, session in ipairs(sessions) do
        items[#items + 1] = { id = session.session_id, title = session.label, icon = "terminal" }
      end
      items[#items + 1] = { id = "rex-hosts", title = "Rex hosts and sessions", icon = "server" }

      local selected = rex.ui.pick({
        title = "Sessions",
        placeholder = "Filter sessions and providers",
        items = items,
      })
      if providers[selected] then
        open_provider(providers[selected], sessions)
      elseif selected == "rex-hosts" then
        rex.client.queue("session.switch")
      elseif selected then
        rex.client.queue("session.select", { session_id = selected })
      end
    end,
  })
  rex.bind("cmd+s", action)
end
