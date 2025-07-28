# Nushell main config.nu (modular, lightweight)
source core/env.nu
source core/aliases.nu
source core/extras.nu
source core/prompt.nu

# Carapace integration
let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
$env.config.show_banner = false
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
