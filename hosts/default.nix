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

  lima-dev = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    config = ./lima-dev;

    sysinit = common.sysinit;

    values = common.values // (import ./lima-dev/values.nix);
  };

  lima-minimal = {
    system = "aarch64-linux";
    platform = "linux";
    username = "dev";

    config = ./lima-minimal;

    sysinit = common.sysinit;

    values = common.values // (import ./lima-minimal/values.nix);
  };
}
