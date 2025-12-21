{
  pkgs,
  ...
}:

{
  services.displayManager.ly = {
    enable = true;
    package = pkgs.ly;
  };
}
