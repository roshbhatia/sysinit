{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? npm && userConfig.npm ? additionalPackages
                      then userConfig.npm.additionalPackages
                      else [];

  basePackages = with pkgs; [
    nodePackages.typescript-language-server
    nodePackages.yaml-language-server
    nodePackages.prettier
    nodePackages.typescript
    nodePackages."@microsoft/inshellisense"
  ];

  allPackages = basePackages ++ additionalPackages;

  # Use $HOME instead of config.home.homeDirectory
  npmGlobalDir = "$HOME/.npm-global";
in
{
  home.packages = allPackages;

  home.sessionVariables.NPM_CONFIG_PREFIX = npmGlobalDir;
  
  home.activation.createNpmGlobalDir = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      $DRY_RUN_CMD mkdir -p ${npmGlobalDir}
    '';
  };
}