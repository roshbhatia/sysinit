# SwayFX compositor + desktop packages
{
  pkgs,
  inputs,
  ...
}:

let
  swayfxPkg = inputs.swayfx.packages.${pkgs.system}.default;

  # Wrap swayfx the same way nixpkgs wraps sway
  swayfxWrapped = pkgs.sway.override {
    sway-unwrapped = swayfxPkg;
  };

  swayWrapped = pkgs.writeShellScriptBin "sway-wrapped" ''
    set -euo pipefail

    export PATH="/run/current-system/sw/bin:$HOME/.nix-profile/bin:$PATH"
    export WLR_NO_HARDWARE_CURSORS=1
    export WLR_RENDERER=vulkan
    export GBM_BACKEND=nvidia-drm
    export __GLX_VENDOR_LIBRARY_NAME=nvidia
    export LIBVA_DRIVER_NAME=nvidia
    export XDG_CURRENT_DESKTOP=sway
    export XDG_SESSION_TYPE=wayland
    export NIXOS_OZONE_WL=1
    export GDK_BACKEND=wayland
    export QT_QPA_PLATFORM=wayland
    export MOZ_ENABLE_WAYLAND=1

    ${pkgs.dbus}/bin/dbus-update-activation-environment --systemd --all || true

    exec ${swayfxWrapped}/bin/sway --unsupported-gpu "$@"
  '';
in
{
  services = {
    xserver.enable = false;
    dbus.enable = true;

    # Sunshine remote desktop
    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };

  programs = {
    sway = {
      enable = true;
      package = swayfxWrapped;
      xwayland.enable = true;
    };

    # Gaming
    steam = {
      enable = true;
      remotePlay.openFirewall = true;
      dedicatedServer.openFirewall = true;
    };
    gamemode.enable = true;

    # 1Password
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "rshnbhatia" ];
    };
  };

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    WLR_RENDERER = "vulkan";
    XDG_CURRENT_DESKTOP = "sway";
    XCURSOR_THEME = "macOS";
    XCURSOR_SIZE = "16";
  };

  # 32-bit graphics (required for Steam/Wine)
  hardware.graphics.enable32Bit = true;

  security.polkit.enable = true;

  environment.systemPackages = with pkgs; [
    swayWrapped
    swaybg
    grim
    slurp
    sway-contrib.grimshot
    wl-clipboard
    cliphist

    # Launcher + notifications + utilities
    rofi
    bemenu
    j4-dmenu-desktop
    mako
    wlr-which-key

    # File management
    nemo

    # Communication
    vesktop

    # Music
    cider

    # Media viewers
    mpv
    imv
    (zathura.override { plugins = [ zathuraPkgs.zathura_pdf_mupdf ]; })

    # Audio control
    pavucontrol

    # Authentication
    polkit_gnome

    # Gaming
    lutris
    mangohud

    # Theming
    papirus-icon-theme
    apple-cursor
    gruvbox-gtk-theme
  ];
}
