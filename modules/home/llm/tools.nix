{
  lib,
  ...
}:
{
  xdg.configFile."bd/config.yaml" = {
    text = lib.generators.toYAML { } {
      json = true;
      no-daemon = true;
    };
    force = true;
  };
}
