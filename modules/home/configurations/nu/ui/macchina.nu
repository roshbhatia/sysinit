#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/macchina.nu (begin)
if ($env.WEZTERM_PANE? == "0") and ($env.NVIM? | is-empty) {
  if ($env.MACCHINA_THEME? | is-not-empty) {
    macchina --theme $env.MACCHINA_THEME
  } else {
    macchina --theme rosh-color
  }
}
# modules/darwin/home/nu/core/macchina.nu (end)

