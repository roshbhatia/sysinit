{ config, pkgs, ... }:
{
  home.file.".hammerspoon/init.lua".source =
     "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/hammerspoon/init.lua";
  home.file.".hammerspoon/lua".source =
     "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/hammerspoon/lua";

  home.file.".hammerspoon/Spoons/VimMode.spoon" = {
    source = pkgs.fetchFromGitHub {
      owner = "dbalatero";
      repo = "VimMode.spoon";
      rev = "dda997f79e240a2aebf1929ef7213a1e9db08e97";
      sha256 = "sha256-zpx2lh/QsmjP97CBsunYwJslFJOb0cr4ng8YemN5F0Y=";
    };
    recursive = true;
  };
}
