{ pkgs, name }:
pkgs.sysinit.writeShellScriptBin name ''
  exec ${pkgs.neovim}/bin/nvim --clean -c "set ft=markdown" "$@"
''
