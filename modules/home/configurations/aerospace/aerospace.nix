{
  ...
}:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
    force = true;
  };

  xdg.configFile."aerospace/smart-resize" = {
    source = ./smart-resize.sh;
    force = true;
  };

  xdg.configFile."aerospace/update-display-cache" = {
    source = ./update-display-cache.sh;
    force = true;
  };
}
