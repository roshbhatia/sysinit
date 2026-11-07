{
  pkgs,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  check =
    base:
    let
      replacement = base.pkgs.extend (
        _final: previous: {
          auditMarker = "replacement";
          trash-cli = previous.hello;
        }
      );
      changed = base.extendModules {
        modules = [
          ({ lib, pkgs, ... }: {
            options.packageSetProbe = lib.mkOption { type = lib.types.str; };
            config = {
              nixpkgs.pkgs = lib.mkForce replacement;
              packageSetProbe = pkgs.auditMarker or "original";
            };
          })
        ];
      };
    in
    changed.config.packageSetProbe == "replacement"
    && changed.config.home-manager.backupCommand == "${replacement.trash-cli}/bin/trash-put";
  configurations = builtins.filter (base: base.config ? home-manager) (
    builtins.attrValues darwinConfigurations ++ builtins.attrValues nixosConfigurations
  );
in
assert lib.assertMsg (lib.all check configurations)
  "module and Home Manager arguments must use the configured package set";
pkgs.runCommand "package-set-composition" { } ''touch "$out"''
