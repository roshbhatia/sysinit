# Host configurations
# Exports a function that takes common config and optional overrides
# and returns host metadata for the builder
{
  common,
  overrides ? { },
}:

let
  # Merge overrides into common config
  mergedCommon = common // overrides;
in
{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (mergedCommon) username;
    config = ./lv426.nix;

    values = {
      inherit (mergedCommon) theme git darwin;
      user.username = mergedCommon.username;
    };
  };

  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    isLima = true;
    inherit (mergedCommon) username;
    config = ./nostromo.nix;

    values = {
      inherit (mergedCommon) theme git;
      user.username = mergedCommon.username;
    };
  };
}
