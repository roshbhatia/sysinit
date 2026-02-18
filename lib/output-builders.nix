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
      let
        baseConfig = buildConfig {
          hostConfig = cfg;
          hostname = name;
        };
      in
      if extraModules == [ ] then baseConfig else baseConfig.extendModules { modules = extraModules; }
    ) configs
    // extras;
}
