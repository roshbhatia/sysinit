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

  xdg.configFile."nvim/init.lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/init.lua";
  xdg.configFile."nvim/lua".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/lua";
  xdg.configFile."nvim/assets/frida.png".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim/assets/frida.png";

  home.activation.nvimXdgPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.cache/nvim"
    run mkdir -p "${config.home.homeDirectory}/.local/state/nvim"
    run chmod -R u+w "${config.home.homeDirectory}/.cache/nvim" 2>/dev/null || true
    run chmod -R u+w "${config.home.homeDirectory}/.local/state/nvim" 2>/dev/null || true
  '';
}

