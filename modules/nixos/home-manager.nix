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

    sharedModules = [
      {
        # NixOS-specific home-manager configuration
        # Manage Stylix targets manually for neovim and firefox
        stylix.targets = {
          neovim.enable = false;
          firefox.enable = false;
          vim.enable = false;
          mako.enable = true;
          waybar.enable = true;
        };
      }
    ];

    users.${values.user.username} =
      {
        ...
      }:
      {
        imports = [
          ../home
          ./home
        ];
      };
  };
}
