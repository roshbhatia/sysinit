let get_alias = {|cmd|
  scope aliases | where name == $cmd | get -o 0.expansion
}

let zoxide_completer = {|spans|
  $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
}

let carapace_completer = {|spans|
  let expanded_alias = ($get_alias | do $in $spans.0)
  let spans = (if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row " " | take 1)
  } else {
    $spans
  })
  carapace $spans.0 nushell ...$spans | from json
}

let external_completer = {|spans|
  let expanded_alias = ($get_alias | do $in $spans.0)
  let spans = if $expanded_alias != null {
    $spans | skip 1 | prepend ($expanded_alias | split row ' ' | take 1)
  } else {
    $spans
  }

  match $spans.0 {
    __zoxide_z | __zoxide_zi => $zoxide_completer
    make => null
    _ => $carapace_completer
  } | do $in $spans
}

$env.config.completions = {
  external: {
    enable: true
    completer: $external_completer
  }
}
