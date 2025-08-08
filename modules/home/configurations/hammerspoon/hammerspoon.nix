{
  config,
  lib,
  values,
  pkgs,
  ...
}:
{
  home.file.".hammerspoon/init.lua".source = ./init.lua;
  home.file.".hammerspoon/lua/app_switcher.lua".source = ./lua/app_switcher.lua;

  home.file.".hammerspoon/Spoons/VimMode.spoon" = {
    source = pkgs.fetchFromGitHub {
      owner = "dbalatero";
      repo = "VimMode.spoon";
      rev = "dda997f79e240a2aebf1929ef7213a1e9db08e97";
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # placeholder, will update
    };
    recursive = true;
  };
}

