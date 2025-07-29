#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/config.nu (begin)
$env.config = {
  show_banner: false
  edit_mode: "vi"
  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    external: {
      enable: false
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

source ~/.config/nushell/aliases.nu
source ~/.config/nushell/atuin.nu
source ~/.config/nushell/carapace.nu
source ~/.config/nushell/direnv.nu
source ~/.config/nushell/kubectl.nu
source ~/.config/nushell/macchina.nu
source ~/.config/nushell/omp.nu
source ~/.config/nushell/zoxide.nu
# modules/darwin/home/nu/core/config.nu (end)

