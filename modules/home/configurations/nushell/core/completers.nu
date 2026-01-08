let get_alias = {|cmd|
  scope aliases | where name == $cmd | get -o 0.expansion
}

let zoxide_completer = {|spans|
  $spans | skip 1 | zoxide query -l ...$in | lines | where {|x| $x != $env.PWD}
}

let z_completer = {|spans|
  let query = if ($spans | length) > 1 { $spans | skip 1 | str join " " } else { "" }
  zoxide query -l | lines | where {|x| $x != $env.PWD } | each {|path|
    {
      value: $path
      description: $"󠀠 $path"
      span: {
        start: (($spans.0 | str length) + 1)
        end: (($spans | str join " ") | str length)
      }
    }
  }
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
    __zoxide_z | __zoxide_zi | z => $z_completer
    k => $carapace_completer
    _ => $carapace_completer
  } | do $in $spans
}

$env.config.completions = {
  external: {
    enable: true
    completer: $external_completer
  }
}
