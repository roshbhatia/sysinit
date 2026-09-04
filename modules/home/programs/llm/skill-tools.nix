{ lib, pkgs, ... }:
let
  askProviderNames = builtins.attrNames pkgs.ask-providers.providers;
  yamlFormat = pkgs.formats.yaml { };
in
{
  home.packages = [
    pkgs.sysinit-utils
    pkgs.ask
    (lib.lowPrio pkgs.ask-providers)
    pkgs.calldiff
  ];

  xdg.configFile =
    builtins.listToAttrs (
      map (name: {
        name = "ask/providers/${name}/provider.yaml";
        value.source = "${pkgs.ask-providers}/share/ask/providers/${name}/provider.yaml";
      }) askProviderNames
    )
    // {
      "ask/config.yaml".source = yamlFormat.generate "ask-config.yaml" {
        version = "ask.config/v1";
        provider.default = "claude";
      };
    };
}
