{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Wayland compositor
    sway
    wl-clipboard
    xwayland

    # Display utilities
    wlr-randr
    swaybg
  ];
}
