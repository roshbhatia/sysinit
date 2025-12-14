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
        stylix.targets.mako.enable = false;
        stylix.targets.foot.enable = false;
        stylix.targets.waybar.enable = false;
        stylix.targets.wofi.enable = false;
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
