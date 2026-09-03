{
  config,
  pkgs,
  ...
}:
let
  yamlFormat = pkgs.formats.yaml { };
  providerNames = [
    "changes"
    "harness"
    "local"
    "traces"
    "wezterm"
    "zmx"
  ];
in
{
  config = {
    home.packages = [
      pkgs.orc-cli
      pkgs.orc-providers
    ];

    xdg.configFile =
      builtins.listToAttrs (
        map (name: {
          name = "orc/providers/${name}/provider.yaml";
          value = {
            source = "${pkgs.orc-providers}/share/orc/providers/${name}/provider.yaml";
          };
        }) providerNames
      )
      // {
        "orc/config.yaml".source = yamlFormat.generate "orc-config.yaml" {
          cache.providerTtlMs = 30000;
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
            inspectorPercent = 28;
          };
        };
      };
  };
}
