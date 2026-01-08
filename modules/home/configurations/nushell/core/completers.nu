def "nu-complete zoxide path" [context: string] {
  # Handle alias expansion for z
  let parts_raw = $context | str trim --left | split row " "
  let expanded_alias = (scope aliases | where name == $parts_raw.0 | get -o 0 | get -o expansion)
  let parts = (
    if $expanded_alias != null {
      $parts_raw | skip 1 | prepend ($expanded_alias | split row " " | take 1) | drop 1 | each { str downcase }
    } else {
      $parts_raw | skip 1 | each { str downcase }
    }
  )
  let completions = (
    ^zoxide query --list --exclude $env.PWD -- ...$parts
      | lines
      | each { |dir|
        if ($parts | length) <= 1 {
          $dir
        } else {
          let dir_lower = $dir | str downcase
          let rem_start = $parts | drop 1 | reduce --fold 0 { |part, rem_start|
            ($dir_lower | str index-of --range $rem_start.. $part) + ($part | str length)
          }
          {
            value: ($dir | str substring $rem_start..)
            description: $dir
          }
        }
      }
  )
  {
    options: {
      sort: false
      completion_algorithm: substring
      case_sensitive: false
    }
    completions: $completions
  }
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

let carapace_completer = {|spans: list<string>|
  carapace $spans.0 nushell ...$spans
    | from json
    | if ($in | default [] | any {|| $in.display | str starts-with "ERR"}) { null } else { $in }
}

let external_completer = {|spans|
  let expanded_alias = (scope aliases | where name == $spans.0 | get -o 0 | get -o expansion)
  let spans = (if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else {
    $spans
  })

  match $spans.0 {
    __zoxide_z | __zoxide_zi => null
    z => null
    k => $carapace_completer
    nu | git => $fish_completer
    _ => $carapace_completer
  } | do $in $spans
}

$env.config.completions = {
  external: {
    enable: true
    completer: $external_completer
  }
}
