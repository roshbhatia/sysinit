# The `$EDITOR` a pi-lineage harness hands to its own external-editor command.
#
# `--clean` skips the user's init.lua, because the editor opens on a scratch file
# the agent wrote and a full config loads plugins that expect a project. The
# filetype is set explicitly: the scratch file usually has no extension, so
# neovim would otherwise open it with no syntax at all.
#
# `name` is the binary name, and it is per-harness rather than shared: both pi
# and atomic can have an editor open at once, and the process list should say
# which agent spawned it.
{ pkgs, name }:
pkgs.writeShellScriptBin name ''
  exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
''
