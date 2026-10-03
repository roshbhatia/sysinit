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
  systemGenerationPruner = pkgs.sysinit.writeShellScript "sysinit-prune-system-generations" (
    builtins.readFile ./prune-system-generations.sh
  );
in
{

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

    builders = "ssh-ng://nix-builder@arrakis.stork-eel.ts.net x86_64-linux /var/root/.ssh/sysinit-builder 8 2 nixos-test,benchmark,big-parallel,kvm - -";
    builders-use-substitutes = true;

    narinfo-cache-negative-ttl = 60;

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
    variables.TERMINFO_DIRS = lib.mkForce [
      "${pkgs.ncurses}/share/terminfo"
      "${pkgs.wezterm.terminfo}/share/terminfo"
      "/usr/share/terminfo"
    ];
    shells = [
      pkgs.bashInteractive
      pkgs.nushell
      pkgs.zsh
    ];

    pathsToLink = [
      "/share/bash-completion"
      "/share/fish"
      "/share/nushell"
    ];

    variables.PATH = lib.mkForce (lib.concatStringsSep ":" systemPath);
  };

  launchd.user.envVariables = {
    PATH =
      commandPath.homeEntriesFor true "/etc/profiles/per-user/${user}/bin"
        config.users.users.${user}.home;
    CODEX_CLI_PATH = lib.getExe pkgs.codex;
    ORC_AGENT_REGISTRY = agentRegistry;
  };

  documentation.enable = false;
  system.tools."darwin-uninstaller".enable = false;

  system = {
    activationScripts.postActivation.text = ''
      /usr/bin/pmset -a disablesleep 0
      /usr/bin/pmset -b displaysleep 5 sleep 10
      /bin/rm -f /var/db/sysinit/closed-lid-ssh-enabled
      /usr/bin/install -d -m 700 /var/root/.ssh
      if [ ! -f /var/root/.ssh/sysinit-builder ]; then
        /usr/bin/ssh-keygen -q -t ed25519 -N "" -C "sysinit-builder-${hostname}" \
          -f /var/root/.ssh/sysinit-builder
      fi
      if ! /usr/bin/cmp -s /etc/nix/nix.custom.conf /var/db/sysinit/nix-settings.applied; then
        /bin/launchctl kickstart -k system/systems.determinate.nix-daemon
        /nix/var/nix/profiles/default/bin/nix store info --store daemon >/dev/null
        /usr/bin/install -d -m 755 /var/db/sysinit
        /usr/bin/install -m 600 /etc/nix/nix.custom.conf /var/db/sysinit/nix-settings.applied
      fi
    '';

    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = config.sysinit.user.username;
    stateVersion = 6;
  };
}
