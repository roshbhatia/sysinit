# Conditionally source tool integrations if they're available
if (which atuin | is-not-empty) {
  source ($nu.config-dir | path join "integrations/atuin.nu")
}

if (which zoxide | is-not-empty) {
  source ($nu.config-dir | path join "integrations/zoxide.nu")
}

if (which direnv | is-not-empty) {
  source ($nu.config-dir | path join "integrations/direnv.nu")
}

if (which carapace | is-not-empty) {
  let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
  $env.config.completions.external = {
    enable: true
    max_results: 100
    completer: $carapace_completer
  }
}

if (which oh-my-posh | is-not-empty) {
  oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --force ~/.cache/omp.nu
  source ~/.cache/omp.nu
}

if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  if (which macchina | is-not-empty) {
    let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
    macchina --theme $macchina_theme
  }
}
