#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/macchina.nu (begin)
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# nushell/core/macchina.nu (begin)
if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  if (which macchina | is-not-empty) {
    let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
    macchina --theme $macchina_theme
  }
}
# modules/darwin/home/nu/core/macchina.nu (end)

