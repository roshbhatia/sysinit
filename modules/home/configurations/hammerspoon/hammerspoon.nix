{
  config,
  lib,
  values,
  ...
}:
{
  home.file.".hammerspoon/init.lua".source = ./init.lua;
  home.file.".hammerspoon/lua/app_switcher.lua".source = ./lua/app_switcher.lua;

  # Fetch VimMode.spoon as a Nix derivation and symlink it into Spoons
  home.file.".hammerspoon/Spoons/VimMode.spoon" = {
    source = pkgs.fetchFromGitHub {
      owner = "dbalatero";
      repo = "VimMode.spoon";
      rev = "dda997f2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2e2"; # latest as of Apr 11, 2022
      sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # placeholder, will update
    };
    recursive = true;
  };
}

