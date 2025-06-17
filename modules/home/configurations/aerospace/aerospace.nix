{
  ...
}:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
    force = true;
  };

  home.file.".local/bin/aerospacectl" = {
    source = ./aerospacectl.sh;
    force = true;
  };
}
