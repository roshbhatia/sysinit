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
        ];
      }
    else
      {
        windowManager = with pkgs; [
          sway
        ];
        terminalEmulator = with pkgs; [
          wezterm
        ];
        browser = with pkgs; [
          firefox
        ];
        systemTools = with pkgs; [
          xorg.xwininfo
          wmctrl
        ];
      };

  commonPackages = with pkgs; [
    git
    gh
    go
    nodejs_22
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

