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

        stylix.targets.bat.enable = true;
        stylix.targets.btop.enable = true;
        stylix.targets.fzf.enable = true;
        stylix.targets.helix.enable = true;
        stylix.targets.k9s.enable = true;
        stylix.targets.nushell.enable = true;
        stylix.targets.vivid.enable = true;
        stylix.targets.wezterm.enable = true;
        stylix.targets.yazi.enable = true;
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
