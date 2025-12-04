try { source ~/.local/share/atuin/init.nu } catch { print "atuin not available" }
try { source ~/.nix-profile/share/zoxide/init.nu } catch { print "zoxide not available" }
try { source ~/.nix-profile/share/direnv/direnv.nu } catch { print "direnv not available" }

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
