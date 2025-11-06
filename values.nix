{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  theme = {
    appearance = "light";
    colorscheme = "gruvbox";
    font = {
      monospace = "CenturySchoolMonospace Nerd Font Mono";
    };
    transparency = {
      opacity = 1.0;
      blur = 100;
    };
  };

  darwin = {
    homebrew = {
      additionalPackages = {
        taps = [
          "qmk/qmk"
        ];
        brews = [
          "qmk"
        ];
        casks = [
          "betterdiscord-installer"
          "calibre"
          "discord"
          "orbstack"
          "steam"
        ];
      };
    };
  };
}
