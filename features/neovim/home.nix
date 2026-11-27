{
  config,
  inputs,
  lib,
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
  programs.neovim.initLua = lib.mkAfter ''
    dofile("${./review-keys.lua}")
  '';
}
