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
    # Display/WM
    sway
    swaybg
    wl-clipboard
    wlr-randr
    xwayland
    
    # Services
    pulseaudio
    flatpak
    wezterm
    tailscale
    
    # Audio
    pavucontrol
    alsa-utils
    pipecontrol
    
    # Virtualization
    qemu_kvm
    qemu
    
    # Gaming
    (heroic.override {
      extraPkgs = pkgs: [ pkgs.gamescope ];
    })
    lutris
    protonup-qt
    mangohud
    goverlay
    vulkan-tools
    vkbasalt
    
    # Compat
    fhsEnv
  ];
in
{
  environment.systemPackages = allPackages;
}
