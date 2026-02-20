{
  values,
  utils,
  inputs ? { },
  stylix,
  ...
}:

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
          stylix.homeManagerModules.stylix
        ];

        sysinit.git = values.git;
        sysinit.theme = {
          appearance = values.theme.appearance;
          colorscheme = values.theme.colorscheme;
          variant = values.theme.variant;
          font.monospace = values.theme.font.monospace;
          transparency = values.theme.transparency;
        };

        # Configure stylix with base16 scheme
        stylix = {
          base16Scheme = "${stylix}/share/stylix/schemes/rose-pine-mute.yaml";
          image = values.theme.image or null;
        };
      };
  };
}
