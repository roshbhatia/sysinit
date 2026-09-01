{
  lib,
  pkgs,
  ...
}:
let
  mkProvider =
    name: runtimeInputs:
    pkgs.writeShellApplication {
      name = "orc-provider-${name}";
      runtimeInputs = [ pkgs.jq ] ++ runtimeInputs;
      text = ''
        export ORC_PROVIDER_KIND=${lib.escapeShellArg name}
        ${builtins.readFile ./provider.sh}
      '';
    };

  providers = {
    changes = {
      capabilities = [ "changes.inspect" ];
      package = mkProvider "changes" [ pkgs.changes ];
    };
    traces = {
      capabilities = [ "session.inspect" ];
      package = mkProvider "traces" [ pkgs.traces ];
    };
    wezterm = {
      capabilities = [ "terminal.open" ];
      package = mkProvider "wezterm" [ pkgs.wezterm ];
    };
    zmx = {
      capabilities = [
        "session.attach"
        "session.launch"
      ];
      package = mkProvider "zmx" [ pkgs.zmx ];
    };
  };
in
{
  config = {
    home.packages = [ pkgs.orc-cli ] ++ lib.mapAttrsToList (_: provider: provider.package) providers;

    xdg.configFile = lib.mapAttrs' (
      name: provider:
      lib.nameValuePair "orc/providers/${name}.json" {
        text = builtins.toJSON {
          inherit name;
          inherit (provider) capabilities;
          command = lib.getExe provider.package;
          priority = 100;
          version = "orc.provider/v1";
        };
      }
    ) providers;
  };
}
