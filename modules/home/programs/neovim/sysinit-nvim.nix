{ lib, pkgs, config, ... }:
let
  nvimRepo = "https://github.com/roshbhatia/sysinit.nvim.git";
  nvimDir = "${config.xdg.configHome}/nvim";
in
{
  # Clone/update sysinit.nvim config on every switch.
  # Nix owns the neovim binary; the git repo owns ~/.config/nvim.
  home.activation.sysinit-nvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_DIR="${nvimDir}"
    if [ ! -d "$NVIM_DIR/.git" ]; then
      $DRY_RUN_CMD ${pkgs.git}/bin/git clone "${nvimRepo}" "$NVIM_DIR"
    else
      $DRY_RUN_CMD ${pkgs.git}/bin/git -C "$NVIM_DIR" pull --ff-only --quiet
    fi
  '';
}
