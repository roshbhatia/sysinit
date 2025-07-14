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

  xdg.configFile."nvim/init.lua" = {
    source = ./init.lua;
    force = true;
  };

  xdg.configFile."nvim/lua" = {
    source = ./lua;
    force = true;
  };

  # Ensure XDG directories have correct permissions for Neovim plugins
  home.activation.nvimXdgPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run mkdir -p "${config.home.homeDirectory}/.cache/nvim"
    run mkdir -p "${config.home.homeDirectory}/.local/state/nvim" 
    run chmod -R u+w "${config.home.homeDirectory}/.cache/nvim" 2>/dev/null || true
    run chmod -R u+w "${config.home.homeDirectory}/.local/state/nvim" 2>/dev/null || true
  '';
}
