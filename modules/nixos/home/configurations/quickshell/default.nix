{
  lib,
  config,
  pkgs,
  ...
}:

{
  # Quickshell QML configs managed via home.file with mkOutOfStoreSymlink
  # This allows live-editing without rebuilds during testing
  
  home.packages = with pkgs; [
    quickshell
    qt6.full
  ];

  # Configure QML files for live-editing
  home.file = {
    ".config/quickshell/shell.qml".source = lib.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/quickshell/shell.qml";
    ".config/quickshell/launcher.qml".source = lib.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/quickshell/launcher.qml";
    ".config/quickshell/settings.qml".source = lib.mkOutOfStoreSymlink
      "${config.home.homeDirectory}/.config/quickshell/settings.qml";
  };

  # Initial QML files (will be replaced by live-editable symlinks)
  xdg.configFile = {
    "quickshell/shell.qml".text = builtins.readFile ./qml/shell.qml;
    "quickshell/launcher.qml".text = builtins.readFile ./qml/launcher.qml;
    "quickshell/settings.qml".text = builtins.readFile ./qml/settings.qml;
  };
}
