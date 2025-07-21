{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
  themes = import ../../../lib/themes { inherit lib; };
  batTheme = themes.getAppTheme "bat" overlay.theme.colorscheme overlay.theme.variant;
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

  # Conditionally include theme files based on current colorscheme
  xdg.configFile = lib.mkMerge [
    (lib.mkIf (overlay.theme.colorscheme == "catppuccin") {
      "bat/themes/Catppuccin-Frappe.tmTheme" = {
        source = ./Catppuccin-Frappe.tmTheme;
        force = true;
      };
      "bat/themes/Catppuccin-Latte.tmTheme" = {
        source = ./Catppuccin-Latte.tmTheme;
        force = true;
      };
      "bat/themes/Catppuccin-Macchiato.tmTheme" = {
        source = ./Catppuccin-Macchiato.tmTheme;
        force = true;
      };
      "bat/themes/Catppuccin-Mocha.tmTheme" = {
        source = ./Catppuccin-Mocha.tmTheme;
        force = true;
      };
    })

    (lib.mkIf (overlay.theme.colorscheme == "rose-pine") {
      "bat/themes/rose-pine.tmTheme" = {
        source = ./rose-pine.tmTheme;
        force = true;
      };
      "bat/themes/rose-pine-moon.tmTheme" = {
        source = ./rose-pine-moon.tmTheme;
        force = true;
      };
      "bat/themes/rose-pine-dawn.tmTheme" = {
        source = ./rose-pine-dawn.tmTheme;
        force = true;
      };
    })

    (lib.mkIf (overlay.theme.colorscheme == "gruvbox") {
      "bat/themes/gruvbox-dark.tmTheme" = {
        source = ./gruvbox-dark.tmTheme;
        force = true;
      };
      "bat/themes/gruvbox-light.tmTheme" = {
        source = ./gruvbox-light.tmTheme;
        force = true;
      };
    })
  ];

  home.activation.buildBatCache = activation.mkActivationScript {
    description = "Build bat cache";
    requiredExecutables = [ "bat" ];
    script = ''
      log_command "bat cache --build" "Building bat cache"
    '';
  };
}
