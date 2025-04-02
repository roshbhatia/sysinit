{pkgs, lib, config, userConfig ? {}, ...}:

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
in
{
  home.packages = allPackages;

  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  
  home.activation.createNpmGlobalDir = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD mkdir -p ${config.home.homeDirectory}/.npm-global
  '';
}