{
  lib,
  pkgs,
  ...
}:
let
  # cocoindex-code[full] bundles the local-embeddings stack
  # (sentence-transformers + sqlite-vec + the snowflake-arctic-embed-xs
  # model on first use). Build-from-source through nix is infeasible because
  # PyTorch is in the dependency closure; pipx gives a self-contained venv
  # outside the nix store, mirroring how the pi config module shells out to
  # bun for plugin installs.
  pipx = "${pkgs.pipx}/bin/pipx";

  installCocoindex = pkgs.writeShellScript "install-cocoindex-code" ''
    set -euo pipefail

    if ${pipx} list --short 2>/dev/null | ${pkgs.gawk}/bin/awk '{print $1}' | grep -qx "cocoindex-code"; then
      echo "install-cocoindex-code: cocoindex-code already installed; nothing to do"
      exit 0
    fi

    echo "install-cocoindex-code: pipx install 'cocoindex-code[full]' (one-time, ~5 GB)"
    ${pipx} install --include-deps 'cocoindex-code[full]'
  '';
in
{
  home.activation.installCocoindexCode = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD ${installCocoindex}
  '';
}
