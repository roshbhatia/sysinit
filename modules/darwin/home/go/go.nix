{ pkgs, lib, config, userConfig ? {}, ... }:

let
  packageManager = import ../../../lib/package-manager.nix { inherit lib; };
in packageManager.mkPackageManager {
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
  executablePath = "/etc/profiles/per-user/$USER/bin/go";
}
