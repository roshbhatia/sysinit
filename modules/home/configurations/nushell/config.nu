#/usr/bin/env nu

$env.config.show_banner = false
$env.config.edit_mode = "vi"

let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
$env.config.completions = {
  case_sensitive: false
  quick: true
  partial: true
  algorithm: "fuzzy"
  external: {
    enable: true
    max_results: 100
    completer: $carapace_completer
  }
}

try { source ~/.local/share/atuin/init.nu } catch { }
try { source ~/.nix-profile/share/zoxide/init.nu } catch { }
try { source ~/.nix-profile/share/direnv/direnv.nu } catch { }

if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
  macchina --theme $macchina_theme
}

oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --raw ~/.cache/omp.nu
source ~/.cache/omp.nu

