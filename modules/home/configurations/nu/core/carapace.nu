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
    let expanded_alias = scope aliases
    | where name == $spans.0
    | get -i 0.expansion

    let spans_for_completion = if $expanded_alias != null {
        $spans
        | skip 1
        | prepend ($expanded_alias | split row ' ' | take 1)
    } else {
        $spans
    }

    match $spans_for_completion.0 {
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

