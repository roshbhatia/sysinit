{ homeConfigurations, pkgs }:
let
  inherit (pkgs) lib;
  inherit (pkgs.stdenv.hostPlatform) system;
  minimal = homeConfigurations."minimal-${system}";
  dev = homeConfigurations."dev-${system}";
  featureNames = lib.concatMap (
    file: builtins.attrNames ((import file).flake.modules.homeManager or { })
  ) (import ../../features/module-exports.nix);
in
assert lib.assertMsg (
  builtins.length featureNames == builtins.length (lib.unique featureNames)
) "Home Manager feature names must have one owner";
assert lib.assertMsg (
  !minimal.config.programs.nushell.enable && !(minimal.options.sysinit ? queue)
) "The minimal profile must omit desktop Nushell and the task queue";
assert lib.assertMsg (
  dev.config.programs.nushell.enable
  && (dev.options.sysinit ? queue)
  && !dev.config.sysinit.queue.enable
) "The development profile must configure Nushell and make the task queue available on request";
pkgs.runCommand "home-profiles" { } "touch $out"
