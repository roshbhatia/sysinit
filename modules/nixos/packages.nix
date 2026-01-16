# System packages
{ pkgs, ... }:

let
  fhsEnv = pkgs.buildFHSEnv (
    let
      base = pkgs.appimageTools.defaultFhsEnvArgs;
    in
    base
    // {
      name = "fhs";
      targetPkgs = pkgs: (base.targetPkgs pkgs) ++ [ pkgs.pkg-config ];
      profile = "export FHS=1";
      runScript = "bash";
      extraOutputsToInstall = [ "dev" ];
    }
  );
in
{
  environment.systemPackages = with pkgs; [
    # Core utilities
    brightnessctl
    dbus
    grim
    jq
    lua54Packages.cjson
    mesa-demos
    networkmanager
    slurp
    wl-clipboard
    xclip
    xsel

    # Fonts
    nerd-fonts.agave

    # Desktop environment
    fuzzel
    mako
    swww
    waybar
    wlr-randr
    xwayland

    # Audio
    alsa-utils
    pavucontrol
    pipecontrol
    pulseaudio

    # Gaming
    (heroic.override { extraPkgs = pkgs: [ pkgs.gamescope ]; })
    gamescope
    goverlay
    mangohud
    vkbasalt
    vulkan-extension-layer
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers

    # Terminal & utilities
    wezterm
    tailscale
    nemo
    fhsEnv
  ];
}
