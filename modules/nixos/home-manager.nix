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
        stylix.targets = {
          # We do this stuff more manually
          neovim.enable = false;
          firefox.enable = false;

          mako.enable = true;
          waybar.enable = true;
          wofi.enable = true;
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
