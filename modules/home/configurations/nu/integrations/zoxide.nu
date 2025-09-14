#!/usr/bin/env nu
# shellcheck disable=all
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

def "nu-complete zoxide path" [context: string] {
    let parts = $context | split row " " | skip 1
    {
      options: {
        sort: false,
        completion_algorithm: substring,
        case_sensitive: false,
      },
      completions: (^zoxide query --list --exclude $env.PWD -- ...$parts | lines),
    }
  }

def --env --wrapped z [...rest: string@"nu-complete zoxide path"] {
  __zoxide_z ...$rest
}

alias z = __zoxide_z
alias zi = __zoxide_zi

