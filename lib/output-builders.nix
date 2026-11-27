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
        extraModules = extraModules ++ (cfg.extraModules or [ ]);
      }
    ) configs
    // extras;
}
