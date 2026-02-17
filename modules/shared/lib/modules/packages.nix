{ lib, ... }:

let
  inherit (lib) mkOption types;

  mkPackageManagerOptions = name: {
    additionalPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Additional packages to install via ${name}";
    };
  };
in
{
  options.sysinit = {
    cargo = mkPackageManagerOptions "cargo";
    gh = mkPackageManagerOptions "gh";
    go = mkPackageManagerOptions "go";
    nix = mkPackageManagerOptions "nix";
    npm = mkPackageManagerOptions "npm";
    pipx = mkPackageManagerOptions "pipx";
    uvx = mkPackageManagerOptions "uvx";
    vet = mkPackageManagerOptions "vet";
    yarn = mkPackageManagerOptions "yarn";
  };
}
