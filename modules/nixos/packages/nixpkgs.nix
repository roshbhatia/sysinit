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

  # Core system utilities
  basePkgs = with pkgs; [
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
    nerd-fonts.agave
  ];

  # Display and compositor
  displayPkgs = with pkgs; [
    dmenu
    dmenu-wayland
    swaybg
    waybar
    wlr-randr
    xwayland
  ];

  # Audio
  audioPkgs = with pkgs; [
    alsa-utils
    pavucontrol
    pipecontrol
    pulseaudio
  ];

  # Gaming tools
  gamingPkgs = with pkgs; [
    (heroic.override {
      extraPkgs = pkgs: [ pkgs.gamescope ];
    })
    gamescope
    goverlay
    mangohud
    vkbasalt
    vulkan-extension-layer
    vulkan-loader
    vulkan-tools
    vulkan-validation-layers
  ];

  # Terminal and shells
  terminalPkgs = with pkgs; [
    wezterm
  ];

  # Development and virtualization
  devPkgs = [
    fhsEnv
  ];

  # System utilities
  utilityPkgs = with pkgs; [
    tailscale
  ];

  # File manager
  fileMgrPkgs = with pkgs; [
    nemo
  ];

  allPackages =
    basePkgs
    ++ displayPkgs
    ++ audioPkgs
    ++ gamingPkgs
    ++ terminalPkgs
    ++ devPkgs
    ++ utilityPkgs
    ++ fileMgrPkgs;
in
{
  environment.systemPackages = allPackages;
}
