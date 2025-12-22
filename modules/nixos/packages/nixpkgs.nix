{
  pkgs,
  ...
}:

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

  allPackages = with pkgs; [
    alsa-utils
    dmenu
    dmenu-wayland
    fhsEnv
    flatpak
    goverlay
    (heroic.override {
      extraPkgs = pkgs: [ pkgs.gamescope ];
    })
    lutris
    mangohud
    pavucontrol
    pipecontrol
    protonup-qt
    pulseaudio
    qemu
    qemu_kvm
    tailscale
    vkbasalt
    vulkan-extension-layer
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers
    wezterm
    wl-clipboard
    wlr-randr
    xwayland
  ];
in
{
  environment.systemPackages = allPackages;
}
