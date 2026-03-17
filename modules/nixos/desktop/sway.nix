{
  pkgs,
  inputs,
  ...
}:

let
  swayfxPkg = inputs.swayfx.packages.${pkgs.system}.default;

  swayfxWrapped = pkgs.sway.override {
    sway-unwrapped = swayfxPkg;
  };
in
{
  services = {
    xserver.enable = false;
    dbus.enable = true;

    sunshine = {
      enable = true;
      openFirewall = true;
      capSysAdmin = true;
    };
  };

  programs = {
    _1password.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "rshnbhatia" ];
    };

    gamemode.enable = true;
    steam = {
      dedicatedServer = {
        openFirewall = true;
      };
      enable = true;
      remotePlay = {
        openFirewall = true;
      };
    };

    sway = {
      enable = true;
      package = swayfxWrapped;
      xwayland = {
        enable = true;
      };
    };
  };
}
