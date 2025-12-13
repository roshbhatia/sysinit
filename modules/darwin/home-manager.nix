{
  values,
  utils,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit utils values;
    };
    sharedModules = [
      {
        stylix.targets.neovim.enable = false;
        stylix.targets.vim.enable = false;
        stylix.targets.firefox.enable = false;
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
