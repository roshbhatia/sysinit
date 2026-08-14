{ lib, inputs }:
{
  mkHome =
    {
      home-manager,
      mkPkgs,
      mkOverlays,
    }:
    {
      system,
      username,
      hostname,
      profile ? "dev",
      theme ? false,
      values ? { },
    }:
    let
      pkgs = mkPkgs {
        inherit system;
        overlays = mkOverlays system;
      };

      homeDirectory = if lib.hasSuffix "darwin" system then "/Users/${username}" else "/home/${username}";

      resolved = {
        inherit hostname;
        isDesktop = false;
        git = { };
        llm = { };
        theme = { };
        darwin = { };
        environment = { };
      }
      // values
      // {
        user = (values.user or { }) // {
          inherit username;
        };
      };
    in
    home-manager.lib.homeManagerConfiguration {
      inherit pkgs;

      extraSpecialArgs = {
        inherit inputs profile theme;
        values = resolved;
      };

      modules = [
        ../../modules/shared/options/theme.nix
        ../../modules/home/programs/llm/options.nix
        ../../modules/home/programs/git/options.nix
        ../../modules/home
        {
          home = {
            inherit username homeDirectory;
          };

          sysinit = {
            git = resolved.git;
            llm = resolved.llm;
            theme = resolved.theme;
          };
        }
      ];
    };
}
