# Ported from the zsh tree so a nushell pane keeps the same command surface.
# @seshySessions@ is substituted at build time. The zsh copy resolves the same
# root by calling `sysinit_path`, which is defined nowhere and on no PATH, so it
# has always taken its own fallback branch instead.
const SESHY_ROOT = "@seshySessions@"

def sysinit-ls-icon [kind: string] {
  match $kind {
    dir => (char --integer 0xf07b)
    symlink => (char --integer 0xf0c1)
    socket => (char --integer 0xf6a7)
    pipe => (char --integer 0xf569)
    _ => (char --integer 0xf15b)
  }
}

def ls [
  --all (-a)
  --long (-l)
  --short-names (-s)
  --full-paths (-f)
  --du (-d)
  --directory (-D)
  --mime-type (-m)
  --threads (-t)
  ...pattern: glob
]: [nothing -> table] {
  let pattern = if ($pattern | is-empty) { [.] } else { $pattern }
  (%ls
    --all=$all
    --long=$long
    --short-names=$short_names
    --full-paths=$full_paths
    --du=$du
    --directory=$directory
    --mime-type=$mime_type
    --threads=$threads
    ...$pattern
  )
  | insert icon {|row| sysinit-ls-icon $row.type }
  | move icon --before name
}

alias ll = ls --all --long

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

alias nuvim-plugin-context = nuvim context
alias nuvim-plugin-servers = nuvim servers

def --env nuvim [] {
  if ($env.NVIM? | default "" | is-not-empty) {
    return (nuvim-plugin-context)
  }

  let servers = (nuvim-plugin-servers)
  if ($servers | is-empty) {
    error make {msg: "nuvim: no running Neovim sessions found"}
  }

  let selected = if ($servers | length) == 1 {
    $servers | first
  } else {
    $servers
    | input list --display {|server| $"($server.label)  ($server.cwd)  pid ($server.pid)"} "Choose a Neovim session:"
  }

  $env.NVIM = $selected.server
  nuvim-plugin-context
}

$env.config.hooks.env_change.PWD = (
  $env.config.hooks.env_change.PWD?
  | default []
  | append {||
    let session = (sysinit-seshy-session $env.PWD)
    if ($session | is-empty) {
      hide-env --ignore-errors SYSINIT_WORKSPACE
    } else {
      $env.SYSINIT_WORKSPACE = $"($SESHY_ROOT)/($session)"
    }
  }
)

# `pre_execution` only marks work, so interactive readers never race a terminal capture.
$env.config.hooks.pre_execution = (
  $env.config.hooks.pre_execution?
  | default []
  | append {||
    if ($env.ASK_CAPTURE? | default "1") == "1" and ($env.WEZTERM_PANE? | is-not-empty) {
      $env.ASK_CAPTURE_ID = ($env.WEZTERM_PANE | into string)
      $env.ASK_CAPTURE_PENDING = "1"
    }
  }
)

$env.config.hooks.pre_prompt = (
  $env.config.hooks.pre_prompt?
  | default []
  | append {||
    if ($env.ASK_CAPTURE? | default "1") == "1" and ($env.WEZTERM_PANE? | is-not-empty) {
      $env.ASK_CAPTURE_ID = ($env.WEZTERM_PANE | into string)
      let initialized = ($env.ASK_CAPTURE_INITIALIZED? | default "0") == "1"
      let command_finished = ($env.ASK_CAPTURE_PENDING? | default "0") == "1"

      if (
        (not $initialized or $command_finished)
        and (which ask | is-not-empty)
        and (which wezterm | is-not-empty)
      ) {
        do --ignore-errors {
          let snapshot = (
            ^@timeout@ 0.25 wezterm cli --no-auto-start get-text --pane-id $env.WEZTERM_PANE
            | complete
          )
          if $snapshot.exit_code == 0 {
            $snapshot.stdout | ^ask --capture
          }
        }
      }

      $env.ASK_CAPTURE_INITIALIZED = "1"
    }

    hide-env --ignore-errors ASK_CAPTURE_PENDING
  }
)
