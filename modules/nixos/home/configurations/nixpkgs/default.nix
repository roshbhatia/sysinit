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
    mako
    dconf
    jq
    socat
    wl-clipboard
  ];
}
