{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  providerNames = builtins.attrNames pkgs.orc-providers.providers;
in
{
  config = {
    home = {
      packages = [
        pkgs.orc-cli
      ];
      sessionVariables.ORC_AGENT_REGISTRY = "${config.xdg.configHome}/sysinit/agents.json";
    };

    xdg.configFile =
      builtins.listToAttrs (
        map (name: {
          name = "orc/providers/${name}/provider.yaml";
          value.source = "${pkgs.orc-cli}/share/orc/providers/${name}/provider.yaml";
        }) providerNames
      )
      // {
        "orc/config.yaml".source = yamlFormat.generate "orc-config.yaml" {
          cache.providerTtlMs = 30000;
          daemon = {
            autostart = true;
            scanIntervalMs = 5000;
            idleShutdownSeconds = 60;
            terminationRetrySeconds = 60;
          };
          lifecycle = {
            runtimeTimeoutSeconds = 28800;
            idleTimeoutSeconds = 1800;
          };
          providers = {
            directory = "${config.xdg.configHome}/orc/providers";
            timeoutMs = 15000;
          };
          workflows = {
            repository = "${config.xdg.dataHome}/orc/workflows";
            autoCommit = true;
            maxDepth = 10;
          };
          ui = {
            refreshMs = 5000;
            activityRefreshMs = 10000;
            inspectorPercent = 38;
          };
        };
      };
  };
}
