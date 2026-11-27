{
  flake.modules.nixos.remoteBuild = { config, ... }: {
    boot.binfmt = {
      emulatedSystems = [ "aarch64-linux" ];
      preferStaticEmulators = true;
    };

    users.groups.nix-builder = { };
    users.users.nix-builder = {
      isSystemUser = true;
      group = "nix-builder";
      shell = config.users.users.root.shell;
      openssh.authorizedKeys.keys = [
        ''restrict,command="${config.nix.package}/bin/nix-daemon --stdio" ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgLQuRNF3ji49cm1muC4fY2leyMgAg9q9GJsxVJirB5 sysinit-builder-CLK69JXNPK''
      ];
    };
    nix.settings.trusted-users = [
      "root"
      "nix-builder"
    ];
  };
}
