{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.configFile."wezterm/plugins/bar" = {
    source = pkgs.fetchFromGitHub {
      owner = "adriankarlen";
      repo = "bar.wezterm";
      rev = "660b4e01a64731b588536ffdf6c5876d9de8261c";
      sha256 = "sha256-r964JXGz3+LG9uqbfnw60dkINYlBQicpeVFtQK7y47I=";
    };
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./init.lua;

  xdg.configFile."wezterm/lua" = {
    source = ./lua;
    recursive = true;
  };
}
