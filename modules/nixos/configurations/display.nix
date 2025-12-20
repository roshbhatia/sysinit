{
  pkgs,
  ...
}:

{
  programs.hyprland = {
    enable = true;
    package = pkgs.hyprland;
    xwayland.enable = true;
  };

  services.displayManager.ly = {
    enable = true;
    package = pkgs.ly;
  };

  environment.systemPackages = with pkgs; [
    hyprland
    xwayland
  ];

  services.xserver.enable = false;
}
