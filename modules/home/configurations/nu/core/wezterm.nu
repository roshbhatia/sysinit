#!/usr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# modules/darwin/home/nu/core/wezterm.nu (begin)
def wezterm_set_user_var [name value] {
  if (which base64 | is-empty) == false {
    if ($env.TMUX? | is-empty) {
      print (char escape) + "]1337;SetUserVar=" + $name + "=" + ($value | encode base64) + (char bel)
    } else {
      print (char escape) + "Ptmux;" + (char escape) + "]1337;SetUserVar=" + $name + "=" + ($value | encode base64) + (char bel) + (char escape) + "\\"
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
  print (char escape) + "]7;file://" + (hostname) + ($env.PWD) + (char escape) + "\\"
}

def-env __wezterm_semantic_precmd_executing [] {
  let ret = $env.LAST_EXIT_CODE
  if $env.__wezterm_semantic_precmd_executing != "0" {
    $env.__wezterm_save_prompt = $env.PROMPT
  }
  if ($env.__wezterm_semantic_precmd_executing? | is-empty) == false {
    print (char escape) + "]133;D;" + $ret + ";aid=" + ($env.PID) + (char bel)
  }
  print (char escape) + "]133;A;cl=m;aid=" + ($env.PID) + (char bel)
  $env.__wezterm_semantic_precmd_executing = "0"
}

def-env __wezterm_semantic_preexec [command] {
  if ($env.__wezterm_save_prompt? | is-empty) == false {
    $env.PROMPT = $env.__wezterm_save_prompt
    hide-env __wezterm_save_prompt
  }
  print (char escape) + "]133;C;" + (char bel)
  $env.__wezterm_semantic_precmd_executing = "1"
}

def-env __wezterm_user_vars_precmd [] {
  wezterm_set_user_var WEZTERM_PROG ""
  wezterm_set_user_var WEZTERM_USER (whoami)
  if ($env.TMUX? | is-empty) == false {
    wezterm_set_user_var WEZTERM_IN_TMUX "1"
  } else {
    wezterm_set_user_var WEZTERM_IN_TMUX "0"
  }
  if ($env.WEZTERM_HOSTNAME? | is-empty) {
    if ("/proc/sys/kernel/hostname" | path exists) {
      wezterm_set_user_var WEZTERM_HOST (open "/proc/sys/kernel/hostname" | str trim)
    } else if (which hostname | is-empty) == false {
      wezterm_set_user_var WEZTERM_HOST (hostname)
    } else if (which hostnamectl | is-empty) == false {
      wezterm_set_user_var WEZTERM_HOST (hostnamectl hostname)
    } else {
      wezterm_set_user_var WEZTERM_HOST "unknown"
    }
  } else {
    wezterm_set_user_var WEZTERM_HOST ($env.WEZTERM_HOSTNAME)
  }
}

def-env __wezterm_user_vars_preexec [command] {
  wezterm_set_user_var WEZTERM_PROG $command
}

# Registration
if ($env.WEZTERM_SHELL_SKIP_SEMANTIC_ZONES? | is-empty) {
  $env.PRE_PROMPT_HOOKS = ($env.PRE_PROMPT_HOOKS? | default [] | append __wezterm_semantic_precmd_executing)
  $env.PRE_EXEC_HOOKS = ($env.PRE_EXEC_HOOKS? | default [] | append __wezterm_semantic_preexec)
}

if ($env.WEZTERM_SHELL_SKIP_USER_VARS? | is-empty) {
  $env.PRE_PROMPT_HOOKS = ($env.PRE_PROMPT_HOOKS? | default [] | append __wezterm_user_vars_precmd)
  $env.PRE_EXEC_HOOKS = ($env.PRE_EXEC_HOOKS? | default [] | append __wezterm_user_vars_preexec)
}

if ($env.WEZTERM_SHELL_SKIP_CWD? | is-empty) {
  $env.PRE_PROMPT_HOOKS = ($env.PRE_PROMPT_HOOKS? | default [] | append wezterm_osc7)
}
# modules/darwin/home/nu/core/wezterm.nu (end)

