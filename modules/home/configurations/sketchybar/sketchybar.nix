{ ... }:

{
  xdg.configFile = {
    "sketchybar/plugins/aerospace.sh" = {
      source = ./plugins/aerospace.sh;
      executable = true;
    };

    "sketchybar/plugins/front_app.sh" = {
      source = ./plugins/front_app.sh;
      executable = true;
    };

    "sketchybar/plugins/clock.sh" = {
      source = ./plugins/clock.sh;
      executable = true;
    };

    "sketchybar/plugins/volume.sh" = {
      source = ./plugins/volume.sh;
      executable = true;
    };

    "sketchybar/plugins/battery.sh" = {
      source = ./plugins/battery.sh;
      executable = true;
    };

    "sketchybar/plugins/apple_menu.sh" = {
      source = ./plugins/apple_menu.sh;
      executable = true;
    };
  };
}
