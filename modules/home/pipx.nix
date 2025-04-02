{pkgs, lib, config, userConfig ? {}, ...}:

let
  additionalPackages = if userConfig ? pipx && userConfig.pipx ? additionalPackages
                      then userConfig.pipx.additionalPackages
                      else [];

  basePackages = [];

  allPackages = basePackages ++ additionalPackages;
in
{
  programs.pipx = {
    enable = true;
    packages = allPackages;
  };
}