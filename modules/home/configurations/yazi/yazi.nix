{
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };

in
{
  xdg.configFile = {
    "macchina/macchina.toml" = {
      source = tomlFormat.generate "macchina.toml" {
        theme = "rosh";
      };
      force = true;
    };

  };
}
