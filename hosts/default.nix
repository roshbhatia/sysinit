# Host configurations
common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    config = ./lv426.nix;

    sysinit = common.sysinit;

    values = common.values // {
      # lv426-specific overrides (if any)
    };
  };

  ascalon = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    config = ./ascalon.nix;

    sysinit = common.sysinit;

    values = common.values // {
      # ascalon-specific overrides (if any)
    };
  };
}
