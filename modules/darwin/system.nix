{
  config,
  lib,
  pkgs,
  hostname,
  ...
}:

let
  commandPath = import ../shared/command-path.nix { inherit lib; };
  systemPath = commandPath.systemEntriesFor true;
  user = config.sysinit.user.username;
  agentRegistry = "/Users/${user}/.config/sysinit/agents.json";
  userPath = commandPath.renderFor true "/etc/profiles/per-user/${user}/bin";
in
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

  environment = {
    shells = [
      pkgs.bashInteractive
      pkgs.nushell
      pkgs.zsh
    ];

    # Nushell and the Fish fallback discover package-owned completions through
    # XDG_DATA_DIRS. Darwin only links Zsh's tree unless these paths are named.
    pathsToLink = [
      "/share/fish"
      "/share/nushell"
    ];

    variables.PATH = lib.mkForce (lib.concatStringsSep ":" systemPath);
  };

  launchd.user.envVariables = {
    PATH = commandPath.entriesFor true "/etc/profiles/per-user/${user}/bin";
    ORC_AGENT_REGISTRY = agentRegistry;
  };

  documentation.enable = false;
  system.tools."darwin-uninstaller".enable = false;

  system = {
    # launchd user variables do not survive logout or reboot. Persist the
    # default and update the current GUI session during activation.
    activationScripts.postActivation.text = ''
      user_id="$(/usr/bin/id -u -- ${lib.escapeShellArg user})"
      /bin/launchctl config user path ${lib.escapeShellArg userPath}
      /bin/launchctl asuser "$user_id" /bin/launchctl setenv PATH ${lib.escapeShellArg userPath}
      /bin/launchctl asuser "$user_id" /bin/launchctl setenv ORC_AGENT_REGISTRY ${lib.escapeShellArg agentRegistry}
    '';

    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = config.sysinit.user.username;
    stateVersion = 6;
  };
}
