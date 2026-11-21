return function(settings)
  rex.action({
    name = "sysinit_apply_appearance",
    title = "Apply sysinit appearance",
    category = "Appearance",
    run = function()
      rex.client.queue(
        "client.setting.interface.appearance.scheme",
        { value = settings.appearance }
      )
      rex.client.queue("client.theme.import", { path = settings.themeFile })
      rex.client.queue("client.setting.interface.appearance.tint", { value = true })
      rex.client.queue("client.setting.terminal.typography.font", { value = settings.monospace })
      rex.client.queue("client.setting.terminal.typography.size", { value = settings.size })
      rex.client.queue(
        "client.setting.terminal.advanced_fonts.fallback_fonts",
        { value = settings.symbols }
      )
      rex.client.queue("client.setting.interface.pane_padding.horizontal", { value = 8 })
      rex.client.queue("client.setting.interface.pane_padding.vertical", { value = 6 })
    end,
  })
end
