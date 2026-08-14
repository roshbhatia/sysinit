{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

{
  nix = {
    enable = false;
    buildMachines = [
      {
        hostName = "arrakis";
        system = "x86_64-linux";
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
    settings.builders-use-substitutes = true;
  };

  determinateNix.customSettings = {
    experimental-features = "nix-command flakes";
    extra-substituters = "https://roshbhatia.cachix.org https://nix-community.cachix.org https://cache.iog.io https://numtide.cachix.org https://devenv.cachix.org";
    extra-trusted-public-keys = "roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    trusted-users = [
      "root"
      config.sysinit.user.username
    ];
    fallback = true;
    max-jobs = "auto";
    cores = 0;
    connect-timeout = 10;
  };

  networking.hostName = lib.mkDefault hostname;

  users.users.${config.sysinit.user.username}.home = "/Users/${config.sysinit.user.username}";

  environment.shells = [
    pkgs.bashInteractive
    pkgs.nushell
    pkgs.zsh
  ];

  environment.variables.PATH = lib.mkForce (
    lib.concatStringsSep ":" [
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/bin"
      "/usr/sbin"
      "/sbin"
    ]
  );

  documentation.enable = false;
  system.tools."darwin-uninstaller".enable = false;

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = config.sysinit.user.username;
    stateVersion = 6;
  };
}
