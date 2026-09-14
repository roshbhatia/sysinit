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
  systemGenerationPruner = pkgs.writeShellScript "sysinit-prune-system-generations" (
    builtins.readFile ./prune-system-generations.sh
  );
in
{
  # Determinate owns nix here. nix-darwin gates `environment.etc."nix/machines"`
  # and every `nix.settings` key behind this flag, so a remote builder declared
  # as `nix.buildMachines` is silently dropped. Declare it in customSettings.
  nix.enable = false;

  determinateNix.customSettings = {
    experimental-features = "nix-command flakes";
    extra-substituters = "https://roshbhatia.cachix.org https://nix-community.cachix.org https://numtide.cachix.org https://devenv.cachix.org";
    extra-trusted-public-keys = "roshbhatia.cachix.org-1:K7Kq2esJYhrV/aCH8Xl7h54y8NULg/k+7WkObNT9VDk= nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs= numtide.cachix.org-1:2ps1kLBUWjxIneOy1Ik6cQjb41X0iXVXeHigGmycPPE= devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    trusted-users = [
      "root"
      config.sysinit.user.username
    ];
    fallback = true;
    max-jobs = 2;
    cores = 6;
    connect-timeout = 10;

    # Fields are: uri system sshKey maxJobs speedFactor supported mandatory hostKey.
    #
    # The tailnet FQDN, not the bare name. The daemon runs as root, which does
    # not read the user ssh config that maps `arrakis` to the tailnet. Root
    # resolves the bare name through LAN DNS to 192.168.50.18, so the builder
    # worked at home and vanished anywhere else.
    builders = "ssh-ng://nix-builder@arrakis.stork-eel.ts.net x86_64-linux /var/root/.ssh/sysinit-builder 8 2 nixos-test,benchmark,big-parallel,kvm - -";
    builders-use-substitutes = true;

    # The 3600 default makes a switch within an hour of a cachix push rebuild
    # every path Nix already recorded as missing.
    narinfo-cache-negative-ttl = 60;

    # Determinate defaults this on in /etc/nix/nix.conf. With it on, two
    # consecutive evals of this flake produce different darwin-system
    # derivations, because the flake source gets a fresh store path each time.
    # Every switch then rebuilds the whole home-manager generation, and no CI
    # cache entry can ever match. Measured 2026-09-13: off is also faster,
    # 10.4s against 11.3s per eval.
    lazy-trees = false;
  };

  programs.ssh.knownHosts.arrakis-builder = {
    hostNames = [ "arrakis.stork-eel.ts.net" ];
    publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILFMJdjdiDn8ofDD+3z9w5SDoFdfzocrCxDXtvCemZrj";
  };

  determinateNix.determinateNixd.garbageCollector.strategy = "automatic";

  launchd.daemons.system-generation-prune.serviceConfig = {
    ProgramArguments = [
      "${systemGenerationPruner}"
      "/nix/var/nix/profiles/system"
      "/run/current-system"
      "/nix/var/nix/profiles/default/bin/nix-env"
      "/usr/bin/readlink"
      "/bin/sleep"
      "60"
      "1"
    ];
    ProcessType = "Background";
    RunAtLoad = true;
    StartInterval = 300;
    WatchPaths = [
      "/nix/var/nix/profiles/system"
      "/run/current-system"
    ];
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
    activationScripts.postActivation.text = ''
      /usr/bin/install -d -m 700 /var/root/.ssh
      if [ ! -f /var/root/.ssh/sysinit-builder ]; then
        /usr/bin/ssh-keygen -q -t ed25519 -N "" -C "sysinit-builder-${hostname}" \
          -f /var/root/.ssh/sysinit-builder
      fi
    '';

    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = config.sysinit.user.username;
    stateVersion = 6;
  };
}
