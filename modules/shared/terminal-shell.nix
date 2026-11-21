config: [
  "${config.home.profileDirectory}/bin/nu"
  "--config"
  "${config.xdg.configHome}/nushell/config.nu"
  "--env-config"
  "${config.xdg.configHome}/nushell/env.nu"
  "--plugin-config"
  "${config.xdg.configHome}/nushell/plugin.msgpackz"
]
