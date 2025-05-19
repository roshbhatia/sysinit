{
  ...
}:

{
  programs.neovim = {
    enable = true;
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
}
