{ ... }:

{
  home.file = {
    # Plugin scripts
    ".config/sketchybar/plugins/display_helper.sh" = {
      source = ./plugins/display_helper.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/aerospace.sh" = {
      source = ./plugins/aerospace.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/front_app.sh" = {
      source = ./plugins/front_app.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/clock.sh" = {
      source = ./plugins/clock.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/volume.sh" = {
      source = ./plugins/volume.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/battery.sh" = {
      source = ./plugins/battery.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/system_stats.sh" = {
      source = ./plugins/system_stats.sh;
      executable = true;
    };

    ".config/sketchybar/plugins/apple_menu.sh" = {
      source = ./plugins/apple_menu.sh;
      executable = true;
    };
  };
}
