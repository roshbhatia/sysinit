{ lib, ... }:

let
  lazygitConfig = {
    gui = {
      mouseEvents = false;
      nerdFontsVersion = "3";
    };

    git = {
      scrollPastBottom = false;
      showCommandLog = false;
      showRandomTip = false;
    };

    customCommands = [ ];
  };

in
{
  xdg.configFile."lazygit/config.yml" = {
    text = lib.generators.toYAML { } lazygitConfig;
    force = true;
  };
}
