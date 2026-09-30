{ lib }:

{
  mkConfigurations =
    {
      configs,
      buildConfig,
      extras ? { },

      extraModules ? [ ],
    }:
    lib.mapAttrs (
      name: cfg:
      buildConfig {
        hostConfig = cfg;
        hostname = name;
        inherit extraModules;
      }
    ) configs
    // extras;
}
