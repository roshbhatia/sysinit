{
  pkgs,
  ...
}:

{

  home.packages = with pkgs; [
    quickshell
  ];

  xdg.configFile = {
    "quickshell/shell.qml".text = builtins.readFile ./qml/shell.qml;
    "quickshell/launcher.qml".text = builtins.readFile ./qml/launcher.qml;
    "quickshell/settings.qml".text = builtins.readFile ./qml/settings.qml;
  };
}
