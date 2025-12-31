{
  ...
}:
let
  copilotConfig = builtins.toJSON {
    optional_analytics = true;
  };
in
{
  xdg.configFile.".copilot/config.json".text = copilotConfig;
}
