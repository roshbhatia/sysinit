if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
  macchina --theme $macchina_theme
}
oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --raw ~/.cache/omp.nu
source ~/.cache/omp.nu

