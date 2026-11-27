{
  config,
  getSystem,
  inputs,
  ...
}:
let
  inherit (config) systems;
  inherit (config.flake) nixosConfigurations;
  inherit (inputs) nixpkgs;
  inherit (nixpkgs) lib;

  mkHostLib =
    overrides:
    let
      hostInputs = inputs // overrides;
    in
    import ../lib {
      inherit (hostInputs) nixpkgs;
      inherit (hostInputs.nixpkgs) lib;
      inputs = hostInputs;
    };

  sysinitLib = mkHostLib { };

  personal = import ../hosts/personal.nix;
  hostConfigs = import ../hosts {
    inherit personal;
    inherit (config.flake.modules.nixos) remoteBuild;
  };
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
    inherit mkPkgs;
  };

  darwinConfigurations = outputBuilders.mkConfigurations {
    configs = darwinConfigs;
    inherit buildConfig;
  };

  workstationConfigurations = outputBuilders.mkConfigurations {
    configs = nixosConfigs;
    inherit buildConfig;
  };

  mkPkgs = { system, ... }: (getSystem system).allModuleArgs.pkgs;
  standaloneProfiles = [
    "dev"
    "minimal"
  ];
  outputs = {
    inherit darwinConfigurations;
    nixosConfigurations = workstationConfigurations;

    lib = {
      inherit mkHostLib;
      homeConfigurationTargets = lib.genAttrs systems (
        system: map (profile: "${profile}-${system}") standaloneProfiles
      );
      configurationDerivations = lib.genAttrs systems (
        system:
        let
          forSystem = lib.filterAttrs (_: cfg: cfg.pkgs.stdenv.hostPlatform.system == system);
        in
        {
          darwin = lib.mapAttrs (_: cfg: cfg.system.drvPath) (forSystem darwinConfigurations);
          nixos = lib.mapAttrs (_: cfg: cfg.config.system.build.toplevel.drvPath) (
            forSystem nixosConfigurations
          );
          home = lib.genAttrs standaloneProfiles (
            profile: inputs.self.homeConfigurations.${profile + "-" + system}.activationPackage.drvPath
          );
        }
      );
    };

    homeModules = {
      default = ../modules/home;
      options = {
        imports = [
          ../features/theme/options.nix
          ../modules/home/programs/llm/options.nix
          ../features/git/options.nix
        ];
      };
    };

    homeConfigurations =
      let
        buildHome = builders.mkHome {
          inherit (inputs) home-manager;
          inherit (builders) mkOverlays;
          inherit mkPkgs;
        };
      in
      lib.listToAttrs (
        lib.concatMap (
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
        ) standaloneProfiles
      );

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
  };
in
{
  imports = [ ../hosts/vorgossos/flake-module.nix ];

  systems = [
    "aarch64-darwin"
    "x86_64-linux"
    "aarch64-linux"
  ];

  perSystem =
    { pkgs, system, ... }:
    {
      _module.args.pkgs = builders.mkPkgs {
        inherit system;
        overlays = builders.mkOverlays;
      };

      packages = import ./packages.nix { inherit pkgs; };
      devShells = import ./dev-shells.nix { inherit pkgs; };
      checks = import ../checks {
        inherit
          system
          pkgs
          darwinConfigurations
          nixosConfigurations
          ;
        homeManagerLib = inputs.home-manager.lib;
        inherit (inputs.self) homeConfigurations;
      };
      formatter = import ./formatter.nix { pkgs = nixpkgs.legacyPackages.${system}; };
    };

  flake = outputs;
}
