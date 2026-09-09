{ config, inputs, ... }:
{
  imports = [
    inputs.sysinit-nvim.homeManagerModules.default
    ./options.nix
  ];
  programs.sysinit-neovim = {
    enable = true;
    configPath = config.sysinit.neovim.configPath;
  };
}
