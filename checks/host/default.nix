{
  pkgs,
  darwinConfigurations,
  nixosConfigurations,
}:
let
  inherit (pkgs) lib;
  nuCheck = import ../lib/nushell.nix { inherit pkgs; };
  evalOnly = name: pkgs.runCommand name { } "touch $out";
in
{
  runner-operator = nuCheck {
    name = "runner-operator-check";
    script = ./runner-operator.nu;
    arguments = [
      ../../modules/nixos/runner-operator.nu
      ../fixtures/runner-kubectl.nu
    ];
  };

  nh = import ./nh.nix { inherit pkgs; };

  incremental-defaults = import ./incremental-defaults.nix { inherit pkgs; };

  homebrew-reconcile = import ./homebrew-reconcile.nix { inherit pkgs; };

  app-copy-state = import ./app-copy-state.nix { inherit pkgs; };

  github-runner-guard = import ./github-runner-guard.nix { inherit pkgs; };

  command-path-order = import ./command-path-order.nix { inherit pkgs; };

  comin-darwin =
    let
      inherit (darwinConfigurations.lv426) config;
    in
    assert config.services.comin.enable;
    assert lib.hasPrefix "/nix/var/nix/profiles/default/bin:"
      config.launchd.daemons.comin.serviceConfig.EnvironmentVariables.PATH;
    evalOnly "comin-darwin";

  host-access-security = import ./host-access-security.nix {
    inherit
      pkgs
      darwinConfigurations
      nixosConfigurations
      ;
  };

  cloud-files = import ./cloud-files.nix {
    inherit pkgs lib;
  };

  package-set-composition = import ./package-set.nix {
    inherit pkgs darwinConfigurations nixosConfigurations;
  };

  system-generation-prune =
    if pkgs.stdenv.hostPlatform.isDarwin then
      import ./system-generation-prune.nix { inherit pkgs; }
    else
      evalOnly "system-generation-prune-not-applicable";
}
