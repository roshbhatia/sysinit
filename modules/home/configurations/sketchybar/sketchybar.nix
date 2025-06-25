{
  ...
}:

{
  xdg.configFile."sketchybar/plugins" = {
    source = ./plugins;
    force = true;
  };

  xdg.configFile."sketchybar/sketchybarrc" = {
    source = ./sketchybarrc.sh;
    force = true;
  };
}

