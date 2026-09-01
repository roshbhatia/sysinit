{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;

  cfg = config.sysinit.orc;

  provider = pkgs.writeShellApplication {
    name = "orc-sysinit";
    runtimeInputs = [
      pkgs.changes
      pkgs.jq
      pkgs.traces
      pkgs.wezterm
      pkgs.zmx
    ];
    text = builtins.readFile ./provider.sh;
  };
in
{
  options.sysinit.orc.providers = mkOption {
    type = types.attrsOf types.str;
    default = {
      attach = "sysinit";
      changes = "sysinit";
      inspect = "sysinit";
      launch = "sysinit";
    };
    description = ''
      Orc action routes. Each value resolves to an `orc-<name>` executable on
      PATH. The sysinit provider composes the host session, terminal, trace,
      and change commands outside Orc's core.
    '';
  };

  config = {
    home.packages = [
      pkgs.orc-cli
      provider
    ];

    xdg.configFile."orc/providers.json".text = builtins.toJSON {
      inherit (cfg) providers;
    };
  };
}
