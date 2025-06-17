{
  ...
}:

{
  xdg.configFile."aerospace/aerospace.toml" = {
    source = ./aerospace.toml;
    force = true;
  };

  xdg.configFile."zsh/bin/aerospacectl" = {
    source = ./aerospacectl.sh;
    force = true;
  };
}
