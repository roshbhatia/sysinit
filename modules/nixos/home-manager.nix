{
  values,
  customUtils ? null,
  inputs ? { },
  ...
}:

let
  utils = customUtils;
in
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
