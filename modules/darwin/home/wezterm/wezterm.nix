{
  config,
  lib,
  pkgs,
  ...
}:

{
  xdg.configFile."wezterm/plugins/bar.wezterm" = {
    source = builtins.fetchGit {
      url = "https://github.com/adriankarlen/bar.wezterm.git";
      rev = "660b4e01a64731b588536ffdf6c5876d9de8261c";
      allRefs = true;
    };
  };

  xdg.configFile."wezterm/wezterm.lua".source = ./wezterm.lua;

  xdg.configFile."wezterm/lua" = {
    source = ./lua;
    recursive = true;
  };
}
