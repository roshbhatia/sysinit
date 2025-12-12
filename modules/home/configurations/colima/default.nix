{
  config,
  values,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  configDir = "${values.config.root}/modules/home/configurations/colima";
in
{
  home.file.".colima/default/colima.yaml" = {
    source = mkOutOfStoreSymlink "${configDir}/colima.yaml";
  };
}
