{
  values,
  pkgs,
  ...
}:
{
  nix.enable = false;

  determinate-nix.customSettings = {
    experimental-features = "nix-command flakes";
    lazy-trees = true;
    extra-substituters = "https://nix-community.cachix.org https://cache.iog.io";
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 5;
    "!include" = "nix.secrets.conf";
  };

  environment.shells = [
    pkgs.bashInteractive
    pkgs.nushell
    pkgs.zsh
  ];

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = values.user.username;
    stateVersion = 4;
  };
}
