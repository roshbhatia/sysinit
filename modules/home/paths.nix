{ config, lib, pkgs, ... }:

{
  home.sessionPath = [
    "$HOME/.cargo/bin"
    "$HOME/.yarn/bin"
    "$HOME/.config/yarn/global/node_modules/.bin"
    "$HOME/.local/bin"
    "$HOME/.rvm/bin"
    "$HOME/.krew/bin"
    "$HOME/bin"
    "/opt/homebrew/bin"
    "/opt/homebrew/sbin"
    "/opt/homebrew/opt/gettext/bin"
    "/usr/local/bin"
  ];
  
  home.sessionVariables = {
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
    EDITOR = "nvim";
    VISUAL = "nvim";
    PAGER = "less -R";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };
}