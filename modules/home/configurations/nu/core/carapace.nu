#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/carapace.nu (begin)
if (which carapace | is-not-empty) {
  let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
  $env.config.completions.external = {
    enable: true
    max_results: 100
    completer: $carapace_completer
  }
}
# modules/darwin/home/nu/core/carapace.nu (direnv)

