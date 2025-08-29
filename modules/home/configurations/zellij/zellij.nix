{
  config,
  values,
  ...
}:

let
  zellijConfigPath = "${values.configs.zellij}/config.kdl";
in
{
  home.file."config/zellij/config.kdl".source = config.lib.file.mkOutOfStoreSymlink zellijConfigPath;

  xdg.configFile."zsh/extras/zellij.sh" = {
    source = ./zellij.sh;
  };
}
