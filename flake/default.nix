inputs@{ nixpkgs, ... }:
let
  inherit (nixpkgs) lib;

  sysinitLib = import ../lib {
    inherit lib nixpkgs inputs;
  };

  personal = import ../hosts/personal.nix;
  hostConfigs = import ../hosts { inherit personal; };
  inherit (sysinitLib) builders;
  inherit (sysinitLib) outputBuilders;

  darwinConfigs = lib.filterAttrs (_: cfg: cfg.platform == "darwin") hostConfigs;
  nixosConfigs = lib.filterAttrs (_: cfg: cfg.platform == "linux") hostConfigs;

  buildConfig = builders.buildConfiguration {
    inherit (inputs)
      darwin
      home-manager
      stylix
      onepassword-shell-plugins
      nix-gaming
      ;
    inherit (builders) mkOverlays;
    mkPkgs = { system, ... }: pkgsFor.${system};
  };

  darwinConfigurations = outputBuilders.mkConfigurations {
    configs = darwinConfigs;
    inherit buildConfig;
  };

  workstationConfigurations = outputBuilders.mkConfigurations {
    configs = nixosConfigs;
    inherit buildConfig;
  };
  nixosConfigurations = workstationConfigurations // {
    vorgossos = lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = {
        inherit (inputs) k0s-nix;
        inherit (personal) authorizedKeys;
        terminalColors = personal.rosePine;
        wezterm = inputs.wezterm-fork.packages.x86_64-linux.default;
      };
      modules = [ ../hosts/vorgossos ];
    };
  };

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  pkgsFor = lib.genAttrs systems (
    system:
    builders.mkPkgs {
      inherit system;
      overlays = builders.mkOverlays;
    }
  );
in
{
  inherit darwinConfigurations nixosConfigurations;

  lib.configurationDerivations = lib.genAttrs systems (system: {
    darwin = lib.mapAttrs (_: cfg: cfg.system.drvPath) (
      lib.filterAttrs (name: _: hostConfigs.${name}.system == system) darwinConfigurations
    );
    nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel.drvPath) (
      lib.filterAttrs (_: cfg: cfg.config.nixpkgs.hostPlatform.system == system) nixosConfigurations
    );
    home = lib.genAttrs [ "dev" "minimal" ] (
      profile: inputs.self.homeConfigurations.${profile + "-" + system}.activationPackage.drvPath
    );
  });

  homeModules = {
    default = ../modules/home;
    options = {
      imports = [
        ../modules/shared/options/theme.nix
        ../modules/home/programs/llm/options.nix
        ../modules/home/programs/git/options.nix
      ];
    };
  };

  homeConfigurations =
    let
      buildHome = builders.mkHome {
        inherit (inputs) home-manager;
        inherit (builders) mkOverlays;
        mkPkgs = { system, ... }: pkgsFor.${system};
      };
    in
    lib.listToAttrs (
      lib.concatMap
        (
          profile:
          map (system: {
            name = "${profile}-${system}";
            value = buildHome {
              inherit system profile;
              inherit (personal) username;
              hostname = "standalone";
              values = {
                inherit (personal) git;
              };
            };
          }) systems
        )
        [
          "dev"
          "minimal"
        ]
    );

  packages = lib.mapAttrs (_: pkgs: import ./packages.nix { inherit pkgs; }) pkgsFor;

  checks = lib.genAttrs systems (
    system:
    import ../checks {
      inherit
        system
        darwinConfigurations
        nixosConfigurations
        ;
      homeManagerLib = inputs.home-manager.lib;
      inherit (inputs.self) homeConfigurations;
      pkgs = pkgsFor.${system};
    }
  );

  devShells = lib.mapAttrs (_: pkgs: import ./dev-shells.nix { inherit pkgs; }) pkgsFor;

  templates = {
    discrete = {
      path = ../templates/discrete;
      description = "Template for discrete host repository consuming sysinit";
    };
  };

  overlays = {
    default =
      final: _prev:
      (lib.composeManyExtensions (import ../overlays/default.nix { inherit inputs; })) final _prev;
  };
  formatter = import ./formatter.nix { inherit nixpkgs systems; };
}
