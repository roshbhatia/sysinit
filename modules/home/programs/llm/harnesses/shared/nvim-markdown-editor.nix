{ pkgs, name }:
pkgs.writeShellScriptBin name ''
  exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
''
