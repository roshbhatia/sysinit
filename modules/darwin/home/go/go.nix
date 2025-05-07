{ pkgs, lib, config, userConfig ? {}, ... }:

let
  activationUtils = import ../../../lib/activation-utils.nix { inherit lib; };
in {
  home.activation.goPackages = activationUtils.mkPackageManager {
    name = "go";
    basePackages = [
      "github.com/x-motemen/gore/cmd/gore@latest"
      "golang.org/x/tools/cmd/godoc@latest"
      "golang.org/x/tools/gopls@latest"
      "golang.org/x/tools/cmd/goimports@latest"
      "mvdan.cc/sh/v3/cmd/shfmt@latest"
    ];
    additionalPackages = if userConfig ? go && userConfig.go ? additionalPackages
      then userConfig.go.additionalPackages
      else [];
    executableArguments = [ "install" ];
    executablePath = "go";  # Using PATH now instead of hardcoded path
  };
}
