{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    quickshell
    nemo
    nwg-look
    hyprshot
    hyprpaper
    swaybg
    grim
    slurp
    swappy
    mako
    dconf
    jq
    socat
    wl-clipboard
  ];
}
