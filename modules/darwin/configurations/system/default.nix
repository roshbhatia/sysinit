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
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    # Connection timeout settings to handle slow downloads and LLVM timeouts
    connect-timeout = 10;
    stalled-download-timeout = 300;
    download-attempts = 3;
    builders-use-substitutes = true;
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
