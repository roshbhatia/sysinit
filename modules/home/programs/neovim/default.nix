{
  config,
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.sysinit-nvim.homeManagerModules.default
    ./options.nix
  ];
  programs.sysinit-neovim = {
    enable = true;
    configPath = config.sysinit.neovim.configPath;
  };
  programs.neovim.plugins = [
    pkgs.sysinit-reviewr
    pkgs.sysinit-editor-workbench
  ];
}
