{
  ...
}:
{
  services.xserver.enable = false;
  # Login managed by greetd in login.nix

  programs.mango.enable = true;

  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    XDG_CURRENT_DESKTOP = "mango";
  };
}
