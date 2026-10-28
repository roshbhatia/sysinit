{
  config,
  lib,
  pkgs,
  ...
}:
let
  home = lib.attrByPath [ "home-manager" "users" config.sysinit.user.username ] { } config;
  cfg = config.sysinit.codex.systemHooks;
  nativeHooks = import ../home/programs/llm/lib/codex-hooks.nix {
    inherit lib pkgs;
    profileBin = "${home.home.profileDirectory}/bin";
  };
in
{
  options.sysinit.codex.systemHooks.enable = lib.mkOption {
    type = lib.types.bool;
    default = home.programs.codex.enable or false;
    description = "Install Nix-owned Codex hooks in the natively trusted system config layer.";
  };

  config = lib.mkIf cfg.enable {
    environment.etc."codex/hooks.json".text = builtins.toJSON { inherit (nativeHooks) hooks; };
  };
}
