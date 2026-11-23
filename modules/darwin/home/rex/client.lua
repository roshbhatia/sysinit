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
      rex.client.queue("client.setting.terminal.typography.font", { value = settings.monospace })
      rex.client.queue("client.setting.terminal.typography.size", { value = settings.size })
      rex.client.queue(
        "client.setting.terminal.advanced_fonts.fallback_fonts",
        { value = settings.symbols }
      )
    end,
  })
end
