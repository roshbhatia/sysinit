#!/usr/bin/env nu

# Nushell main configuration
$env.config = {
  show_banner: false
  edit_mode: "vi"
  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
      enable: false  # Will be enabled in integrations if carapace is available
      max_results: 100
    }
  }
  cursor_shape: {
    vi_insert: underscore
    vi_normal: block
  }
  history: {
    max_size: 50000
    sync_on_enter: true
    file_format: "plaintext"
    isolation: false
  }
  keybindings: [
    {
      name: completion_menu
      modifier: none
      keycode: tab
      mode: [emacs vi_normal vi_insert]
      event: {
        until: [
          { send: menu name: completion_menu }
          { send: menunext }
          { edit: complete }
        ]
      }
    }
  ]
}

# Source modular configuration files
source ~/.config/nushell/env.nu
source ~/.config/nushell/aliases.nu
source ~/.config/nushell/shortcuts.nu
source ~/.config/nushell/integrations.nu

