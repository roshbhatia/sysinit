{
  config,
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
    extra-substituters = "https://nix-community.cachix.org https://cache.iog.io https://numtide.cachix.org https://devenv.cachix.org";
    extra-trusted-public-keys = "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 10;
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

  users.users.${config.sysinit.user.username}.home = "/Users/${config.sysinit.user.username}";

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
    primaryUser = config.sysinit.user.username;
    stateVersion = 4;
  };
}
