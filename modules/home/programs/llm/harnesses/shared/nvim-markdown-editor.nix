# The `$EDITOR` a pi-lineage harness hands to its own external-editor command.
{ pkgs, name }:
pkgs.writeShellScriptBin name ''
  exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
''
