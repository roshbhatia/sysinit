{
  pkgs,
  ...
}:

let
  tomlFormat = pkgs.formats.toml { };

  yaziConfig = {
    show_hidden = true;
  };

in
{
  xdg.configFile = {
    "yazi/yazi.toml" = {
      source = tomlFormat.generate "yazi.toml" yaziConfig;
      force = true;
    };
  };
}
