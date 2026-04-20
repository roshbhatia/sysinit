{ ... }:

{
  imports = [ ./sysinit-nvim.nix ];

  stylix.targets.neovim.enable = false;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    # Load Nix-generated init content (provider paths) via wrapper args instead
    # of writing to ~/.config/nvim/init.lua, so the git repo owns that file.
    sideloadInitLua = true;
  };
}
