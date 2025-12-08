{
  ...
}:

{
  programs.niri.enable = true;

  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };
}
