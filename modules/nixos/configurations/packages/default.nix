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
    network-manager-applet
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
    glxinfo

    # Debugging
    jq
  ];
}
