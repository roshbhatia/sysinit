{
  username,
  overlay,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";

    users.${username} =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        imports = [
          (import ./configurations {
            inherit
              config
              lib
              overlay
              pkgs
              ;
          })
          (import ./packages {
            inherit
              config
              lib
              overlay
              pkgs
              ;
          })
        ];

        home = {
          stateVersion = "23.11";

          # Explicitly install an updated bash shell for use with home-manager
          packages = [ pkgs.bashInteractive ];
        };

        # Activation script to set up the PATH for bash
        # Otherwise, nix-darwin falls back to the system bash, which is unsupported by home-manager
        home.activation.setBash = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
          export PATH="${pkgs.bashInteractive}/bin:$PATH"
        '';
      };
  };
}

