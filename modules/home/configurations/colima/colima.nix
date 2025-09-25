{
  lib,
  ...
}:
{
  home.activation.colimaSetup = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "$HOME/.docker/certs.d"

    sudo rm -f /var/run/docker.sock
    sudo ln -sf $HOME/.colima/default/docker.sock /var/run/docker.sock
  '';
}
