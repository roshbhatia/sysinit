return function(rex, settings)
  local function prefix_session(session_id)
    local hostname = rex.exec({ "/bin/hostname", "-s" })
    local host = assert(hostname.ok and hostname.stdout:match("%S+"), "Could not read Rex hostname")
    local prefix = host .. " / "
    local session = rex.call("session.view", { session_id = session_id })
    if session.label:sub(1, #prefix) ~= prefix then
      rex.call("session.set_label", { session_id = session_id, label = prefix .. session.label })
    end
  end

  rex.action({
    name = "sysinit_configure_client",
    title = "Apply Sysinit terminal settings",
    run = function(ctx)
      rex.client.queue("client.setting.terminal.shell.command", { value = settings.shell })
      rex.client.queue("client.setting.interface.toolbar.layout", { value = "left" })
      rex.client.queue(
        "client.setting.interface.appearance.scheme",
        { value = settings.appearance }
      )
      rex.client.queue("client.theme.import", { path = settings.themeFile })
      rex.client.queue("client.setting.interface.appearance.tint", { value = true })
      rex.client.queue("client.setting.terminal.typography.font", { value = settings.monospace })
      rex.client.queue("client.setting.terminal.typography.style", { value = "Regular" })
      rex.client.queue("client.font.reset")
      rex.client.queue("client.setting.terminal.typography.size", { value = settings.size })
      rex.client.queue("client.setting.terminal.typography.line_height", { reset = true })
      rex.client.queue(
        "client.setting.terminal.advanced_fonts.fallback_fonts",
        { value = settings.symbols }
      )
      rex.client.queue("client.setting.interface.pane_padding.horizontal", { value = 8 })
      rex.client.queue("client.setting.interface.pane_padding.vertical", { value = 6 })
      rex.client.queue("client.setting.interface.active_panes.fade", { value = "both" })
      rex.client.queue("client.setting.interface.active_panes.inactive_window", { value = false })
      local session_id = ctx.session_id or rex.session_id
      if session_id then
        prefix_session(session_id)
      end
    end,
  })

  rex.action({
    name = "sysinit_new_local_session",
    title = "New host-prefixed session",
    run = function()
      local session = rex.call("session.create", {
        initial_windows = {
          {
            layout = rex.layout.block({
              flavor = "com.superlogical.terminal.shell",
              options = { shell = "none", command = settings.shellArgv },
            }),
          },
        },
      })
      prefix_session(session.session_id)
      rex.client.queue("session.select", { session_id = session.session_id })
    end,
  })
  rex.bind("cmd+shift+n", "sysinit_new_local_session")
end
