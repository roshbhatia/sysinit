{ platform, pkgs, ... }:
let
  platformPackages =
    if platform.platform.isDarwin then
      {
        windowManager = [ "aerospace" ];
        terminalEmulator = [ "wezterm" ];
        browser = [ "firefox" ];
        systemTools = [
          "borders"
          "displayplacer"
        ];
      }
    else
      {
        windowManager = with pkgs; [
          i3
          sway
        ];
        terminalEmulator = with pkgs; [
          wezterm
          alacritty
        ];
        browser = with pkgs; [
          firefox
          chromium
        ];
        systemTools = with pkgs; [
          xorg.xwininfo
          wmctrl
        ];
      };

  commonPackages = with pkgs; [
    git
    gh
    golang
    nodejs
    python3
    rustc
    bat
    fd
    fzf
    ripgrep
    jq
    yq
    tree
    htop
    docker
    kubectl
    helm
    terraform
    eza
    atuin
    zoxide
    direnv
  ];
in
{
  inherit platformPackages commonPackages;
}
