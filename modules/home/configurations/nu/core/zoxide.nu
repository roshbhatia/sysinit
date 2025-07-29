#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# modules/darwin/home/nu/core/zoxide.nu (begin)
use std/dirs

export-env {
  $env.config = (
    $env.config?
    | default {}
    | upsert hooks { default {} }
    | upsert hooks.env_change { default {} }
    | upsert hooks.env_change.PWD { default [] }
  )

  let __zoxide_hooked = (
    $env.config.hooks.env_change.PWD
    | any { try { get __zoxide_hook } catch { false } }
  )

  if not $__zoxide_hooked {
    $env.config.hooks.env_change.PWD = (
      $env.config.hooks.env_change.PWD
      | append {
          __zoxide_hook: true,
          code: {|_, dir| zoxide add -- $dir }
        }
    )
  }
}

def --env --wrapped __zoxide_z [...rest: string] {
  let path = match $rest {
    [] => '~'
    [ '-' ] => '-'
    [ $arg ] if ($arg | path type) == 'dir' => $arg
    _ => (zoxide query --exclude $env.PWD -- ...$rest | str trim -r -c "\n")
  }
  dirs add $path
}

def --env --wrapped __zoxide_zi [...rest: string] {
  let path = (zoxide query --interactive -- ...$rest | str trim -r -c "\n")
  dirs add $path
}

alias z = __zoxide_z
alias zi = __zoxide_zi
# modules/darwin/home/nu/core/zoxide.nu (end)

