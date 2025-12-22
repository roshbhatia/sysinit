{
  programs.niri = {
    enable = true;
    programs.niri.settings = {
      binds = {
        "Super+Space" = {
          action = "spawn";
          command = "dmenu_run";
        };
      };
    };
  };

  services.displayManager.sddm = {
    wayland.enable = true;
    enable = true;
  };
}
