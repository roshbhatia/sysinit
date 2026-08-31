# Ported from the zsh tree so a nushell pane keeps the same command surface.
# @seshySessions@ is substituted at build time. The zsh copy resolves the same
# root by calling `sysinit_path`, which is defined nowhere and on no PATH, so it
# has always taken its own fallback branch instead.
const SESHY_ROOT = "@seshySessions@"

def sysinit-seshy-session [dir: string] {
  if ($dir | str starts-with $"($SESHY_ROOT)/") {
    $dir | path relative-to $SESHY_ROOT | split row "/" | first
  } else {
    ""
  }
}

def sysinit-seshy-names [] {
  if (which sy | is-empty) {
    print -e "seshy: sy not found on PATH"
    return []
  }
  let out = (^sy list | complete)
  if $out.exit_code != 0 {
    return []
  }
  $out.stdout
  | lines
  | skip 1
  | each {|line| $line | split row -r '\s+' | first }
  | where {|name| $name | is-not-empty }
}

def --env s [name?: string] {
  if ($name | is-empty) {
    print -e "seshy: usage: s <session>"
    return
  }
  let out = (^sy --greedy $name | complete)
  let target = ($out.stdout | str trim)
  if $out.exit_code != 0 or ($target | is-empty) {
    print -e $"seshy: no session matches ($name)"
    return
  }
  cd $target
}

# zmx holds terminal state in libghostty-vt and hands the client a grid snapshot,
# so OSC never crosses it. A wrapped pane loses OSC 7 and OSC 1337 SetUserVar,
# which is every wezterm surface this config drives. Attaching stays deliberate.
def sz [] {
  if (which zmx | is-empty) {
    print -e "seshy: zmx not found on PATH"
    return
  }
  let session = (sysinit-seshy-session $env.PWD)
  if ($session | is-empty) {
    print -e $"seshy: ($env.PWD) is not inside a seshy session"
    return
  }
  let prefix = ($env.ZMX_SESSION_PREFIX? | default "")
  if ($env.ZMX_SESSION? | default "") == $"($prefix)($session)" {
    return
  }
  ^zmx attach $session
}

def sl [] {
  sysinit-seshy-names
}

def --env si [] {
  let names = (sysinit-seshy-names)
  if ($names | is-empty) {
    return
  }
  let picked = (
    $names
    | str join (char newline)
    | ^fzf --height 40% --reverse --prompt "session> "
    | str trim
  )
  if ($picked | is-empty) {
    return
  }
  s $picked
}

def sysinit-set-user-var [name: string, value: string] {
  print -n $"(ansi -o $'($name)=($value | encode base64)')(char bel)"
}

def wezcopy [...args: string] {
  let data = if ($args | is-empty) { $in | into string } else { $args | str join " " }
  sysinit-set-user-var "1337;SetUserVar=wez_copy" $data
}

def weznot [message: string] {
  sysinit-set-user-var "1337;SetUserVar=wez_not" $message
}

# wezmon needs `eval`, which nushell does not have, so it stays a zsh function
# and this is the shim. argv rides in as positional words, so quoting survives.
def --wrapped wezmon [...args: string] {
  ^zsh -ic 'wezmon "$@"' wezmon ...$args
}

def "path.print" [] {
  $env.PATH | to text | ^bat --style=numbers,grid --language=txt
}

def "env.print" [pattern?: string] {
  let prefix = ($pattern | default "")
  $env
  | transpose name value
  | where {|row| $row.name | str starts-with $prefix }
  | sort-by name
  | each {|row| $"($row.name)=($row.value | into string)" }
  | to text
  | ^bat --style=numbers,grid --language=txt
}

$env.config.hooks.env_change.PWD = (
  $env.config.hooks.env_change.PWD
  | append {||
    let session = (sysinit-seshy-session $env.PWD)
    if ($session | is-empty) {
      hide-env --ignore-errors SYSINIT_WORKSPACE
    } else {
      $env.SYSINIT_WORKSPACE = $"($SESHY_ROOT)/($session)"
    }
  }
)

# Snapshots the pane for `ask --last`, because `wezterm cli` does not expose the
# OSC 133 zones that mark where one command's output starts. Costs 25ms per
# command; set ASK_CAPTURE=0 to turn it off. pre_execution, not pre_prompt, so a
# bare enter does not rotate the snapshots away.
$env.config.hooks.pre_execution = (
  $env.config.hooks.pre_execution?
  | default []
  | append {||
    if ($env.ASK_CAPTURE? | default "1") == "1" and ($env.WEZTERM_PANE? | is-not-empty) {
      if (which ask | is-not-empty) {
        do --ignore-errors { ^ask --capture }
      }
    }
  }
)
