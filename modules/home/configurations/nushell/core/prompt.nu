# Nushell Prompt and Macchina logic (mirrors zsh/core/prompt.sh)
if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  let macchina_theme = ($env.MACCHINA_THEME? | default "rosh-color")
  macchina --theme $macchina_theme
}
oh-my-posh init nu --config ~/.config/oh-my-posh/themes/catppuccin-macchiato.omp.json | save --raw ~/.cache/omp.nu
source ~/.cache/omp.nu
