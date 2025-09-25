{
  lib,
  ...
}:
{
  home.activation.colimaSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.docker/certs.d"

    rm -f /var/run/docker.sock
    ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
  '';
}
