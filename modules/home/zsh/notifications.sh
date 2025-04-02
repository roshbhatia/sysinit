#!/usr/bin/env zsh
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# sysinit.nix-shell::ignore
#       ___           ___           ___           ___           ___
#      /  /\         /  /\         /__/\         /  /\         /  /\
#     /  /::|       /  /:/_        \  \:\       /  /::\       /  /:/
#    /  /:/:|      /  /:/ /\        \__\:\     /  /:/\:\     /  /:/
#   /  /:/|:|__   /  /:/ /::\   ___ /  /::\   /  /:/~/:/    /  /:/  ___
#  /__/:/ |:| /\ /__/:/ /:/\:\ /__/\  /:/\:\ /__/:/ /:/___ /__/:/  /  /\
#  \__\/  |:|/:/ \  \:\/:/~/:/ \  \:\/:/__\/ \  \:\/:::::/ \  \:\ /  /:/
#      |  |:/:/   \  \::/ /:/   \  \::/       \  \::/~~~~   \  \:\  /:/
#      |  |::/     \__\/ /:/     \  \:\        \  \:\        \  \:\/:/
#      |  |:/        /__/:/       \  \:\        \  \:\        \  \::/
#      |__|/         \__\/         \__\/         \__\/         \__\/

# Smart notifications for long-running commands
function notify_when_done() {
  local cmd=$1
  local start_time=$2
  local end_time=$(date +%s)
  local elapsed=$((end_time - start_time))
  
  if [[ $elapsed -gt 1800 ]]; then
    if command -v terminal-notifier &> /dev/null; then
      terminal-notifier -title "Task Complete" -message "Finished: $cmd (took ${elapsed}s)" -sound default
    fi
  fi
}

function preexec_notify() {
  cmd_start_time=$(date +%s)
  cmd_name=$1
}

function precmd_notify() {
  if [[ -n $cmd_start_time ]]; then
    notify_when_done "$cmd_name" $cmd_start_time
    unset cmd_start_time
  fi
}

# Register hooks for notifications
precmd_functions+=(precmd_notify)
preexec_functions+=(preexec_notify)