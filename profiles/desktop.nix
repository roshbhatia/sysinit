{ ... }:

{
  # Desktop environment: GUI apps, window management, theming
  # This profile combines macOS-specific desktop configurations

  imports = [
    # Darwin system-level configurations
    ../modules/darwin/configurations/aerospace.nix
    ../modules/darwin/configurations/borders.nix
    ../modules/darwin/configurations/sketchybar.nix
    ../modules/darwin/configurations/stylix.nix
    ../modules/darwin/configurations/desktop.nix
  ];
}
