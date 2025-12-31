{
  lib,
  ...
}:
{
  xdg.configFile = {
    ".copilot/config.json".text = builtins.toJSON {
      optional_analytics = true;
    };
  };
}
