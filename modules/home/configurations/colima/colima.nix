{
  ...
}:

{
  xdg.configFile."colima/default/colima.yaml" = {
    source = ./colima.yaml;
    force = true;
  };

  xdg.configFile."zsh/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };
}
