{
  lib,
  values,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
  themes = import ../../../lib/themes { inherit lib; };
  batTheme = themes.getAppTheme "bat" values.theme.colorscheme values.theme.variant;
in
{
  xdg.configFile."bat/config".text = ''
    # This is `bat`s configuration file. Each line either contains a comment or
    # a command-line option that you want to pass to `bat` by default. You can
    # run `bat --help` to get a list of all possible configuration options.

    # Specify desired highlighting theme (e.g. "TwoDark"). Run `bat --list-themes`
    # for a list of all available themes
    --theme="${batTheme}"
  '';

  home.activation.buildBatCache = activation.mkActivationScript {
    description = "Build bat cache";
    requiredExecutables = [ "bat" ];
    script = ''
      log_command "bat cache --build" "Building bat cache"
    '';
  };
}
