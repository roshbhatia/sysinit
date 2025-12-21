{
  lib,
  values,
  ...
}:

{
  programs.quickshell = {
    enable = true;
    
    # Define package with all necessary settings
    settings = {
      # Panel/taskbar configuration
      panel = {
        enabled = true;
        autoHide = false;
        position = "top";
        height = 40;
      };
      
      # Application launcher
      launcher = {
        enabled = true;
        keybind = "Super_L Space";
      };
      
      # Settings menu
      settings = {
        enabled = true;
        keybind = "Super_L S";
      };
    };
  };
}
