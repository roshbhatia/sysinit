{ pkgs, lib, config, userConfig ? {}, ... }:

let
  additionalPackages = if userConfig ? npm && userConfig.npm ? additionalPackages
                      then userConfig.npm.additionalPackages
                      else [];

  basePackages = [
    "@microsoft/inshellisense"
    "typescript-language-server"
    "prettier"
    "typescript"
  ];

  allPackages = basePackages ++ additionalPackages;
  npmGlobalDir = "$HOME/.npm-global";
in
{
  home.file.".npmrc".text = ''
    prefix=${npmGlobalDir}
  '';

  home.sessionVariables.NPM_CONFIG_PREFIX = npmGlobalDir;
  
  home.activation.npmPackages = {
    after = [ "writeBoundary" ];
    before = [];
    data = ''
      mkdir -p ${npmGlobalDir}
      
      # Install npm packages globally
      for package in ${lib.escapeShellArgs allPackages}; do
        if ! npm list -g "$package" &>/dev/null; then
          echo "Installing $package globally..."
          npm install -g "$package"
        fi
      done
    '';
  };
}