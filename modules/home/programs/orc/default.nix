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
      kind = "changes";
      package = mkProvider "changes" [ pkgs.changes ];
      priority = 100;
    };
    harness = {
      capabilities = [
        "session.attach"
        "session.bind"
      ];
      kind = "harness";
      package = mkProvider "harness" [ ];
      priority = 100;
    };
    traces = {
      capabilities = [
        "session.bind"
        "session.describe"
        "session.inspect"
      ];
      kind = "activity";
      package = mkProvider "traces" [ pkgs.traces ];
      priority = 100;
    };
    wezterm = {
      capabilities = [
        "session.bind"
        "terminal.open"
      ];
      kind = "display";
      package = mkProvider "wezterm" [ pkgs.wezterm ];
      priority = 100;
    };
    zmx = {
      capabilities = [
        "session.bind"
        "session.launch"
        "session.persist"
      ];
      kind = "persistence";
      package = mkProvider "zmx" [ pkgs.zmx ];
      priority = 200;
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
          inherit (provider) capabilities kind priority;
          command = lib.getExe provider.package;
          version = "orc.provider/v1";
        };
      }
    ) providers;
  };
}
