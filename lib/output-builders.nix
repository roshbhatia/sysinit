{ lib }:

{
  mkConfigurations =
    {
      configs,
      buildConfig,
      extras ? { },
      # Modules every host in `configs` gets on top of the sysinit set. A
      # discrete host repository puts its own `modules/darwin` here.
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
