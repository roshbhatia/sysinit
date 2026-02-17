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
          # Import shared module options
          ../shared/lib/modules/theme.nix
          ../shared/lib/modules/packages.nix
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
            # Package manager additional packages
            config.sysinit.cargo.additionalPackages = values.cargo.additionalPackages or [ ];
            config.sysinit.gh.additionalPackages = values.gh.additionalPackages or [ ];
            config.sysinit.go.additionalPackages = values.go.additionalPackages or [ ];
            config.sysinit.nix.additionalPackages = values.nix.additionalPackages or [ ];
            config.sysinit.npm.additionalPackages = values.npm.additionalPackages or [ ];
            config.sysinit.pipx.additionalPackages = values.pipx.additionalPackages or [ ];
            config.sysinit.uvx.additionalPackages = values.uvx.additionalPackages or [ ];
            config.sysinit.vet.additionalPackages = values.vet.additionalPackages or [ ];
            config.sysinit.yarn.additionalPackages = values.yarn.additionalPackages or [ ];
          }
        ];
      };
  };
}
