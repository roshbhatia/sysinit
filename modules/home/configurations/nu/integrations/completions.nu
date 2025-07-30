#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/completions.nu (begin)

# Environment variable helpers
def --env get-env [name] { $env | get $name }
def --env set-env [name, value] { load-env { $name: $value } }
def --env unset-env [name] { hide-env $name }

# Resolve alias to the actual command name
def resolve_alias [cmd] {
  let aliases = scope aliases
  let alias_def = $aliases | where name == $cmd | get -i 0
  if ($alias_def | is-not-empty) {
    let expansion = $alias_def.expansion
    let next_cmd = $expansion | split row ' ' | get 0
    if ($aliases | where name == $next_cmd | is-not-empty) {
      resolve_alias $next_cmd
    } else {
      $next_cmd
    }
  } else {
    $cmd
  }
}

let carapace_completer = {|spans: list<string>|
  let resolved_cmd = resolve_alias $spans.0
  let spans_for_completion = $spans | skip 1 | prepend $resolved_cmd
  try {
    carapace $spans_for_completion.0 nushell ...$spans_for_completion
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  } catch {
    null
  }
}

let fish_completer = {|spans|
  let resolved_cmd = resolve_alias $spans.0
  let spans_for_completion = $spans | skip 1 | prepend $resolved_cmd
  try {
    fish --command $"complete '--do-complete=($spans_for_completion | str replace --all "'" "\\'" | str join ' ')'"
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
  } catch {
    null
  }
}

let argc_completer = {|spans|
  let resolved_cmd = resolve_alias $spans.0
  let spans_for_completion = $spans | skip 1 | prepend $resolved_cmd
  try {
    argc --argc-compgen nushell $spans_for_completion.0 ...$spans_for_completion
    | from json
    | if ($in | default [] | where value =~ '^-.*ERR$' | is-empty) { $in } else { null }
  } catch {
    null
  }
}

let external_completer = {|spans|
  let resolved_cmd = resolve_alias $spans.0
  let spans_for_completion = $spans | skip 1 | prepend $resolved_cmd

  # Choose the best completer for each command
  let completer = match $resolved_cmd {
    # Commands that work better with fish completions
    "nu" | "nushell" => $fish_completer
    "git" => $fish_completer
    "kubectl" | "kubecolor" => $carapace_completer
    "docker" => $carapace_completer
    "cargo" => $carapace_completer
    "npm" | "yarn" | "pnpm" => $carapace_completer
    "terraform" | "tf" => $carapace_completer
    "helm" => $carapace_completer
    "gh" => $carapace_completer
    "argc" => $argc_completer
    # Default to carapace for everything else
    _ => $carapace_completer
  }

  do $completer $spans_for_completion
}

$env.config = ($env.config | default {} | merge {
  completions: {
    case_sensitive: false
    quick: true
    partial: true
    algorithm: "fuzzy"
    sort: "smart"
    external: {
      enable: true
      max_results: 100
      completer: $external_completer
    }
  }
  table: {
    mode: rounded
    index_mode: auto
    show_empty: true
    padding: { left: 1, right: 1 }
    trim: {
      methodology: wrapping
      wrapping_try_keep_words: true
      truncating_suffix: "..."
    }
  }
})
# modules/darwin/home/nu/core/completions.nu (end)

