return function(settings)
  local apply = "sysinit_apply_settings"
  rex.action({
    name = apply,
    title = "Apply sysinit terminal settings",
    category = "Settings",
    run = function()
      if settings.startupCommand ~= "" then
        rex.client.queue(
          "client.setting.terminal.shell.command",
          { value = settings.startupCommand }
        )
      end
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
      rex.client.queue("client.setting.terminal.selection.copy_on_select", { value = true })
    end,
  })
  rex.bind("ctrl+cmd+shift+a", apply)
end
