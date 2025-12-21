{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    quickshell
    nemo
    nwg-look
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
