# The pi extensions this repository vendors from the installed package into
# `~/.pi/agent/extensions/`.
#
# Its own file so `harnesses/pi/default.nix` and the `pi-no-theme-writer` flake check read one
# list. A second copy in the check is what let the theme-writing extension sit beside
# a declared `theme` unnoticed.
[
  "dirty-repo-guard"
  "git-checkpoint"
  "handoff"
  "input-transform"
  "interactive-shell"
  "preset"
  "reload-runtime"
  "session-name"
  "tools"

  # Vim-style modal editing in the prompt, matching claude's editorMode, goose's
  # EDIT_MODE, and cursor's vimMode. Binds `session_start` only.
  "modal-editor"
  # A todo tool plus /todos, the pi counterpart to Claude's TodoWrite. Binds
  # `session_start` and `session_tree` only.
  "todo"

  # `status-line` and `model-status` are deliberately NOT here. The sidebar
  # already shows the turn count and the active model, so both only restated
  # sidebar data in the footer. `model-status` also wrote an emoji and called
  # console.log on every model change. `preset` is the one status writer left,
  # and it is the only one carrying something the sidebar does not.
]
