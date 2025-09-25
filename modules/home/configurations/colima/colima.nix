{
  lib,
  config,
  ...
}:
{
  home.file."docker.sock" = {
    target = "/var/run/docker.sock";
    source = "${config.home.homeDirectory}/.colima/default/docker.sock";
  };
}
