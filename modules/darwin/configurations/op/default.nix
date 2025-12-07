{
  pkgs,
  lib,
  ...
}:

{
  system.activationScripts.applications.text = lib.mkAfter ''
    install -o root -g wheel -m0555 -D \
      ${lib.getExe pkgs._1password-cli} /usr/local/bin/op
  '';
}
