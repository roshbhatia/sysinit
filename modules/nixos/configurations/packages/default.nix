{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    brightnessctl
    dbus
    dmenu
    grim
    jq
    mesa-demos
    nemo
    networkmanager
    pavucontrol
    slurp
    swaybg
    vulkan-tools
    waybar
    wezterm
    wl-clipboard
    xclip
    xsel
  ];
}
