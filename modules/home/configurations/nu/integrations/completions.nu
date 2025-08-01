$env.CARAPACE_BRIDGES = 'zsh,fish,bash,inshellisense'

def --env get-env [name] { $env | get $name }
def --env set-env [name, value] { load-env { $name: $value } }
def --env unset-env [name] { hide-env $name }

let carapace_completer = {|spans|
  # if the current command is an alias, get it's expansion
  let expanded_alias = (scope aliases | where name == $spans.0 | get --optional 0 | get --optional expansion)

  # handle alias expansion correctly
  let spans = (if $expanded_alias != null {
    # replace the alias with the first word of the expanded alias, keep the rest of the spans
    $spans | skip 1 | prepend ($expanded_alias | split row " " | get 0)
  } else {
    $spans
  })

  carapace $spans.0 nushell ...$spans
  | from json
}

mut current = (($env | default {} config).config | default {} completions)
$current.completions = ($current.completions | default {} external)
$current.completions.external = ($current.completions.external
| default true enable
| default { $carapace_completer } completer)
$env.config = $current

