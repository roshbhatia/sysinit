{
  lib,
  pkgs,
  ...
}:

{
  # Quickshell QML configs - desktop shell components
  # Note: Quickshell integration is optional; Sway is the primary WM
  
  home.packages = with pkgs; [
    quickshell
    qt6.full
  ];

  # QML files for quickshell desktop shell
  # Can be manually edited in ~/.config/quickshell/ for live customization
  xdg.configFile = {
    "quickshell/shell.qml".text = builtins.readFile ./qml/shell.qml;
    "quickshell/launcher.qml".text = builtins.readFile ./qml/launcher.qml;
    "quickshell/settings.qml".text = builtins.readFile ./qml/settings.qml;
  };
}
