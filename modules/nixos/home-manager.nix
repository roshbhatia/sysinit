{
  lib,
  pkgs,
  values,
  utils,
  inputs ? { },
  stylix,
  ...
}:

let
  themes = import ../lib/theme.nix { inherit lib; };
in

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit utils values inputs;
    };

    users.${values.user.username} =
      {
        ...
      }:
      {
        imports = [
          # Shared module options at home-manager level
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home
          stylix.homeModules.stylix
        ];

        # For Lima VMs, explicitly set home to the nix-managed directory
        # (Lima creates /home/rshnbhatia.linux as the actual home, not the mounted /home/rshnbhatia)
        home.homeDirectory = lib.mkIf (values.isLima or false) (lib.mkForce "/home/${values.user.username}.linux");

        sysinit.git = values.git;
        sysinit.theme = {
          appearance = values.theme.appearance;
          colorscheme = values.theme.colorscheme;
          variant = values.theme.variant;
          font.monospace = values.theme.font.monospace;
          transparency = values.theme.transparency;
        };

        # Configure stylix with base16 scheme from host values
        stylix.base16Scheme = themes.getBase16SchemePath pkgs values.theme.colorscheme values.theme.variant;
      };
  };
}
