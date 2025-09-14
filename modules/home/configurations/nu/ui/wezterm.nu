#!/usr/bin/env nu
# shellcheck disable=all
def wezterm_set_user_var [name: string, value: string] {
  if (which base64 | is-empty) == false {
    if not ("TMUX" in $env) {
      print $"(char escape)]1337;SetUserVar=( $name )=( $value | encode base64 )(char bel)"
    } else {
      print $"(char escape)Ptmux;(char escape)]1337;SetUserVar=( $name )=( $value | encode base64 )(char bel)(char escape)\\"
    }
  }
}

def wezterm_osc7 [] {
  if (which wezterm | is-empty) == false {
    do -i { wezterm set-working-directory } | complete
    if $env.LAST_EXIT_CODE == 0 {
      return
    }
  }
  print $"(char escape)]7;file://(hostname)($env.PWD)(char escape)\\"
}

def --env __wezterm_semantic_precmd_executing [] {
  let ret = $env.LAST_EXIT_CODE
  let precmd_executing = if "__wezterm_semantic_precmd_executing" in $env { $env.__wezterm_semantic_precmd_executing } else { "1" }
  if $precmd_executing != "0" {
    $env.__wezterm_save_prompt = $env.PROMPT
  }
  if "__wezterm_semantic_precmd_executing" in $env and $env.__wezterm_semantic_precmd_executing != "" {
    print $"(char escape)]133;D;($ret);aid=($env.PID)(char bel)"
  }
  print $"(char escape)]133;A;cl=m;aid=($env.PID)(char bel)"
  $env.__wezterm_semantic_precmd_executing = "0"
}

def --env __wezterm_semantic_preexec [command: string] {
  if "__wezterm_save_prompt" in $env {
    $env.PROMPT = $env.__wezterm_save_prompt
    hide-env __wezterm_save_prompt
  }
  print $"(char escape)]133;C;(char bel)"
  $env.__wezterm_semantic_precmd_executing = "1"
}

def --env __wezterm_user_vars_precmd [] {
  wezterm_set_user_var WEZTERM_PROG ""
  wezterm_set_user_var WEZTERM_USER (whoami)
  if "TMUX" in $env {
    wezterm_set_user_var WEZTERM_IN_TMUX "1"
  } else {
    wezterm_set_user_var WEZTERM_IN_TMUX "0"
  }

  if not ("WEZTERM_HOSTNAME" in $env) {
    if ( '/proc/sys/kernel/hostname' | path exists ) {
      wezterm_set_user_var WEZTERM_HOST (open "/proc/sys/kernel/hostname" | str trim)
    } else if (which hostname | is-empty) == false {
      wezterm_set_user_var WEZTERM_HOST (hostname)
    } else if (which hostnamectl | is-empty) == false {
      wezterm_set_user_var WEZTERM_HOST (hostnamectl hostname)
    } else {
      wezterm_set_user_var WEZTERM_HOST "unknown"
    }
  } else {
    wezterm_set_user_var WEZTERM_HOST ($env | get WEZTERM_HOSTNAME)
  }
}

def --env __wezterm_user_vars_preexec [command: string] {
  wezterm_set_user_var WEZTERM_PROG $command
}

# Registration
if not ("WEZTERM_SHELL_SKIP_SEMANTIC_ZONES" in $env) {
  $env.PRE_PROMPT_HOOKS = (if "PRE_PROMPT_HOOKS" in $env { $env.PRE_PROMPT_HOOKS } else { [] } | append __wezterm_semantic_precmd_executing)
  $env.PRE_EXEC_HOOKS = (if "PRE_EXEC_HOOKS" in $env { $env.PRE_EXEC_HOOKS } else { [] } | append __wezterm_semantic_preexec)
}

if not ("WEZTERM_SHELL_SKIP_USER_VARS" in $env) {
  $env.PRE_PROMPT_HOOKS = (if "PRE_PROMPT_HOOKS" in $env { $env.PRE_PROMPT_HOOKS } else { [] } | append __wezterm_user_vars_precmd)
  $env.PRE_EXEC_HOOKS = (if "PRE_EXEC_HOOKS" in $env { $env.PRE_EXEC_HOOKS } else { [] } | append __wezterm_user_vars_preexec)
}

if not ("WEZTERM_SHELL_SKIP_CWD" in $env) {
  $env.PRE_PROMPT_HOOKS = (if "PRE_PROMPT_HOOKS" in $env { $env.PRE_PROMPT_HOOKS } else { [] } | append wezterm_osc7)
}

