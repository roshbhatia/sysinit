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
        imports = [
          ../home
          ./home
          # Import shared theme module options
          ../shared/lib/modules/theme.nix
          # Inline module to set sysinit values from common.nix values
          {
            config.sysinit.git = values.git;
            config.sysinit.theme = {
              appearance = values.theme.appearance;
              colorscheme = values.theme.colorscheme;
              variant = values.theme.variant;
              font.monospace = values.theme.font.monospace;
              transparency = values.theme.transparency;
            };
          }
        ];
      };
  };
}
