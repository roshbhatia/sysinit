{
  pkgs,
  config,
  lib,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;

  # Fantasma font from GitHub
  fantasmaFont = pkgs.fetchzip {
    url = "https://github.com/froyotam/Fantasma/archive/main.zip";
    sha256 = "sha256-wUJzMYBm4Gma4Ev6CA6jvPz3xog6HAquti59Q0DEyl0=";
    stripRoot = false;
    postFetch = ''
      mkdir -p $out
      cp -r $sourceRoot/Fantasma-main/fonts/*.{otf,ttf} $out/ 2>/dev/null || true
    '';
  };
in
{
  home.file = {
    ".local/share/fonts/Fantasma-Regular.otf" = {
      source = "${fantasmaFont}/Fantasma-Regular.otf";
    };
    ".local/share/fonts/Fantasma-Regular.ttf" = {
      source = "${fantasmaFont}/Fantasma-Regular.ttf";
    };
  };

  home.activation.rebuildFontCache = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    if command -v fc-cache &> /dev/null; then
      $DRY_RUN_CMD fc-cache -fv ~/.local/share/fonts
    fi
  '';
}
