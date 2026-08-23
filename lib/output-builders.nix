{ lib }:

{
  mkConfigurations =
    {
      configs,
      buildConfig,
      extras ? { },
    }:
    lib.mapAttrs (
      name: cfg:
      buildConfig {
        hostConfig = cfg;
        hostname = name;
      }
    ) configs
    // extras;
}
