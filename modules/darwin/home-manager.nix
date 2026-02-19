{
  values,
  utils,
  inputs ? { },
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
        home.enableNixpkgsReleaseCheck = false;
        imports = [
          # Shared module options at home-manager level
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          # Cross-platform home modules
          ../home

          # Darwin-specific home modules
          ./home
        ];

        sysinit.git = values.git;
        sysinit.theme = {
          appearance = values.theme.appearance;
          colorscheme = values.theme.colorscheme;
          variant = values.theme.variant;
          font.monospace = values.theme.font.monospace;
          transparency = values.theme.transparency;
        };
      };
  };
}
