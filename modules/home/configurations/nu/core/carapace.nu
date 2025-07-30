#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/carapace.nu (begin)
$env.CARAPACE_BRIDGES = 'zsh,bash'

# Define carapace completer with alias expansion support
def carapace-completer [spans] {
  let expanded_alias = (
    scope aliases
    | where name == $spans.0
    | get -i 0
    | get -i expansion
  )

  let spans = if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else {
    $spans | skip 1 | prepend ($spans.0)
  }

  carapace $spans.0 nushell ...$spans | from json
}

# Configure external completions using the custom completer
$env.config = ($env.config
  | default {}
  | merge {
      completions: {
        external: {
          enable: true
          max_results: 100
          completer: carapace-completer
        }
      }
    }
)

def --env get-env [name] {
  $env | get $name
}

def --env set-env [name, value] {
  load-env { $name: $value }
}

def --env unset-env [name] {
  hide-env $name
}
# modules/darwin/home/nu/core/carapace.nu (direnv)

