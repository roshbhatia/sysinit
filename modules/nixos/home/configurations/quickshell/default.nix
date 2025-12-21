{
  lib,
  values,
  ...
}:

{
  # Quickshell placeholder - QML configs managed via home.file with mkOutOfStoreSymlink
  # This allows live-editing without rebuilds
  
  home.packages = [ ];
  
  # TODO: Configure quickshell QML files in ~/.config/quickshell/ via home.file
  # - Panel/taskbar: shell.qml
  # - Application launcher: launcher.qml
  # - Settings menu: settings.qml
}
