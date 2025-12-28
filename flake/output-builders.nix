{ lib }:

{
  # Generic builder for system configurations
  # Applies buildConfig to all matching systems and merges with extras
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
