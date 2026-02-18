common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    config = ./lv426;

    sysinit = common.sysinit;

    values = common.values // (import ./lv426/values.nix);
  };

  ascalon = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    config = ./ascalon;

    sysinit = common.sysinit;

    values = common.values // { };
  };
}
