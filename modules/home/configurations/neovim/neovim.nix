{
  config,
  lib,
  ...
}:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
    withNodeJs = true;
    withPython3 = true;
    withRuby = true;
  };

  # Use out-of-store symlinks for live Neovim config editing
  xdg.configFile."nvim/init.lua".source =
    pkgs.lib.mkOutOfStoreSymlink "/Users/rbha18/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";
  xdg.configFile."nvim/lua".source =
    pkgs.lib.mkOutOfStoreSymlink "/Users/rbha18/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua";

  # Ensure XDG directories have correct permissions for Neovim plugins
  home.activation.nvimXdgPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.cache/nvim"
    run mkdir -p "${config.home.homeDirectory}/.local/state/nvim" 
    run chmod -R u+w "${config.home.homeDirectory}/.cache/nvim" 2>/dev/null || true
    run chmod -R u+w "${config.home.homeDirectory}/.local/state/nvim" 2>/dev/null || true
  '';
}
