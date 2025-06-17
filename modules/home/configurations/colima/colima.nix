{
  ...
}:

{
  # Colima has issues respecting XDG, and hacky brew service edits don't persist.
  home.file.".colima/_templates/colima.yaml" = {
    source = ./colima.yaml;
    force = true;
  };

  xdg.configFile."zsh/bin/colimactl" = {
    source = ./colimactl.sh;
    force = true;
  };
}
