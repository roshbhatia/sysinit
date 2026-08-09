{ ... }:

{
  imports = [ ./sysinit-nvim.nix ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    sideloadInitLua = true;
  };
}
