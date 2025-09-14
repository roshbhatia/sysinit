#!/usr/bin/env nu
# shellcheck disable=all
if ($env.WEZTERM_PANE? == "0") and ($env.NVIM? | is-empty) {
  if ($env.SYSINIT_MACCHINA_THEME? | is-not-empty) {
    macchina --theme $env.SYSINIT_MACCHINA_THEME
  } else {
    macchina --theme rosh
  }
}

