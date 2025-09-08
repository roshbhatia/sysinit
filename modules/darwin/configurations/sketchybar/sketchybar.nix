{
  pkgs,
  ...
}:
{
  services.sketchybar = {
    package = pkgs.sketchybar;
    enable = true;
  };

  environment.systemPackages = with pkgs; [
    sbarlua
    luajitPackages.cjson
  ];
}
