{
  values,
  inputs ? { },
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit values inputs;
    };

    sharedModules = [
      {
        stylix.targets = {
          neovim.enable = false;
          vim.enable = false;
          firefox.enable = false;
          mako.enable = false;
          waybar.enable = false;
          wofi.enable = false;
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
