if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  if (which macchina | is-not-empty) {
    let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
    macchina --theme $macchina_theme
  }
}
