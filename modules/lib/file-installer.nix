# File installer module for sysinit
{ nixpkgs, self, config, ... }:
let
  inherit (nixpkgs) lib;

  installFiles = config.install or [];
  
  # Function to install a single file
  installFile = { source, destination }:
    let
      srcPath = if lib.strings.hasPrefix "/" source
               then source
               else toString (self + "/${source}");
      destPath = toString destination;
    in ''
      echo "Installing file: ${destPath}"
      mkdir -p "$(dirname "${destPath}")"
      cp -f "${srcPath}" "${destPath}"
      chmod 644 "${destPath}"
    '';
    
  # Generate installation script for all files
  installScript = lib.concatMapStrings installFile installFiles;

in {
  system.activationScripts.postUserActivation.text = lib.mkIf (installFiles != []) ''
    echo "Installing configured files..."
    ${installScript}
  '';
}
