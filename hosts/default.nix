# Host configurations
common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common)
      username
      git
      theme
      darwin
      ;
    config = ./lv426.nix;

    sysinit.git = common.git;
    values = {
      inherit (common) theme git darwin;
      user.username = common.username;
    };
  };

  ascalon = {
    system = "aarch64-linux";
    platform = "linux";
    inherit (common) username git theme;
    config = ./ascalon.nix;

    sysinit.git = common.git;
    values = {
      inherit (common) theme git;
      user.username = common.username;
    };
  };
}
