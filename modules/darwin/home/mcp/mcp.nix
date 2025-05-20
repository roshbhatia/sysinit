{
  ...
}:

{
  xdg.configFile."mcphub/servers.json" = {
    source = ./mcphub.json;
    force = true;
  };

  xdg.configFile."goose/config.yaml" = {
    source = ./google.yaml;
    force = true;
  };

  xdg.configFile."goose/.goosehints" = {
    source = ./goosehints;
    force = true;
  };
}
