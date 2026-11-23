return function(rex, settings)
  rex.action({
    name = "sysinit_configure_client",
    title = "Apply Sysinit terminal settings",
    run = function()
      rex.client.queue("client.setting.terminal.shell.command", { value = settings.shell })
      rex.client.queue("client.setting.interface.toolbar.layout", { value = "left" })
      rex.client.queue(
        "client.setting.interface.appearance.scheme",
        { value = settings.appearance }
      )
      rex.client.queue("client.theme.import", { path = settings.themeFile })
      rex.client.queue("client.setting.interface.appearance.style", {
        value = settings.transparent and "glass" or "classic",
      })
      rex.client.queue("client.setting.interface.appearance.tint", { value = true })
      rex.client.queue("client.setting.interface.appearance.glass", { value = false })
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
    end,
  })
end
