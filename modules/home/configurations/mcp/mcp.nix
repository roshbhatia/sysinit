{
  ...
}:

{
  xdg.configFile."mcphub/servers.json" = {
    source = ./mcphub.json;
    force = true;
  };

  xdg.configFile."goose/config.yaml" = {
    source = ./goose.yaml;
    force = true;
  };

  xdg.configFile."goose/.goosehints" = {
    source = ./goosehints.md;
    force = true;
  };

  xdg.configFile."opencode/.opencode.json" = {
    source = ./opencode.json;
    force = true;
  };
}

