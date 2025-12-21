{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # Wayland/Sway essentials
    sway
    waybar
    wofi
    wezterm
    swaybg

    # Required utilities
    pavucontrol
    networkmanager
    dbus

    # System utils
    brightnessctl
    grim
    slurp
    xclip
    xsel
    wl-clipboard

    # File manager
    nemo

    # Display and GPU tools
    vulkan-tools
    mesa-demos

    # Debugging
    jq
  ];
}
