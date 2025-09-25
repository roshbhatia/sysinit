{
  lib,
  ...
}:
{
  home.sessionVariables = {
    DOCKER_HOST = "unix://$HOME/.colima/default/docker.sock";
  };

  home.activation.colimaSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    # Ensure .docker directory exists
    mkdir -p "$HOME/.docker/certs.d"
  '';
}
