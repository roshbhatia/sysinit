#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all

def --env get-env [name] { $env | get $name }
def --env set-env [name, value] { load-env { $name: $value } }
def --env unset-env [name] { hide-env $name }

$env.PATH = ($env.PATH | split row (char esep) | prepend "/Users/rshnbhatia/.config/carapace/bin")

if (which carapace | is-not-empty) {
  # Carapace completer with error filtering
  let carapace_completer = {|spans: list<string>|
    carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  }

  let fish_completer = {|spans|
    fish --command $"complete '--do-complete=($spans | str replace --all "'" "\\'" | str join ' ')'"
    | from tsv --flexible --noheaders --no-infer
    | rename value description
    | update value {|row|
      let value = $row.value
      let need_quote = ['\' ',' '[' ']' '(' ')' ' ' '\t' "'" '"' "`"] | any {$in in $value}
      if ($need_quote and ($value | path exists)) {
        let expanded_path = if ($value starts-with ~) {$value | path expand --no-symlink} else {$value}
        $'"($expanded_path | str replace --all "\"" "\\\"")"'
      } else {$value}
    }
  }

  let external_completer = {|spans|
    def resolve_alias [cmd] {
  let aliases = scope aliases
  let expansion = aliases | where name == $cmd | get -i 0.expansion
  if $expansion != null {
    let next_cmd = $expansion | split row ' ' | take 1
    if (aliases | where name == $next_cmd | is-not-empty) {
      resolve_alias $next_cmd
    } else {
      $next_cmd
    }
  } else {
    $cmd
  }
}

let resolved_cmd = resolve_alias $spans.0
let spans_for_completion = $spans | skip 1 | prepend $resolved_cmd

match $resolved_cmd {
  nu => $fish_completer
  git => $fish_completer
  kubectl => $fish_completer
  _ => $carapace_completer
} | do $in $spans_for_completion
  }

  # Configure external completions in $env.config
  $env.config = ($env.config | default {} | merge {
    completions: {
      external: {
        enable: true
        max_results: 100
        completer: $external_completer
      }
    }
  })
}
# modules/darwin/home/nu/core/carapace.nu (end)

