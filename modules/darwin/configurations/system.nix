{
  values,
  pkgs,
  hostname,
  ...
}:

{
  # Disable nix-darwin's nix module - using Determinate Nix Installer which manages the Nix daemon
  nix.enable = false;

  determinateNix.customSettings = {
    experimental-features = "nix-command flakes";
    lazy-trees = true;
    extra-substituters = "https://nix-community.cachix.org https://cache.iog.io";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs=";
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 10;
    stalled-download-timeout = 300;
    download-attempts = 3;
    builders-use-substitutes = true;
  };

  nix.buildMachines = [
    {
      hostName = "arrakis";
      system = "aarch64-linux";
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
      maxJobs = 8;
      speedFactor = 2;
      protocol = "ssh-ng";
      sshUser = "rshnbhatia";
      sshKey = "/Users/rshnbhatia/.ssh/id_ed25519";
    }
  ];

  nix.settings.builders-use-substitutes = true;

  networking.hostName = hostname;

  users.users.${values.user.username}.home = "/Users/${values.user.username}";

  environment.shells = [
    pkgs.bashInteractive
    pkgs.nushell
    pkgs.zsh
  ];

  environment.variables.PATH = pkgs.lib.mkForce (
    pkgs.lib.concatStringsSep ":" [
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]
  );

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = values.user.username;
    stateVersion = 4;
  };
}
