{
  lib,
  pkgs,
  config,
  ...
}:
let
  nvimRepo = "https://github.com/roshbhatia/sysinit.nvim.git";
  nvimDir = "${config.xdg.configHome}/nvim";
in
{
  # Clone/update sysinit.nvim config on every switch.
  # Nix owns the neovim binary; the git repo owns ~/.config/nvim.
  home.activation.sysinit-nvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_DIR="${nvimDir}"
    GIT=${pkgs.git}/bin/git
    if [ ! -d "$NVIM_DIR/.git" ]; then
      $DRY_RUN_CMD "$GIT" clone "${nvimRepo}" "$NVIM_DIR"
    elif [ -n "$("$GIT" -C "$NVIM_DIR" status --porcelain)" ]; then
      echo "sysinit-nvim: $NVIM_DIR has uncommitted changes, skipping pull" >&2
    else
      $DRY_RUN_CMD "$GIT" -C "$NVIM_DIR" pull --ff-only --no-rebase --quiet \
        || echo "sysinit-nvim: pull failed, continuing activation" >&2
    fi
  '';
}
