{
  lib,
  config,
  ...
}:
let
  # See options.nix for why this is its own option and not `programs.nh.flake`.
  configSource = config.sysinit.neovim.configPath;
  nvimDir = "${config.xdg.configHome}/nvim";
in
{
  imports = [ ./options.nix ];

  # ~/.config/nvim is a symlink into this repository's working tree, not a store
  # path and not a second clone.
  #
  # Not `xdg.configFile`: lazy.nvim writes `lazy-lock.json` into the config root,
  # which a read-only store tree cannot accept, and a config in the store needs a
  # switch to test a keymap. Pointing at the working tree keeps the edit loop at
  # "edit, restart nvim" and keeps the lockfile tracked in git where its drift is
  # visible.
  home.activation.sysinit-nvim = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    NVIM_DIR="${nvimDir}"
    WANT="${configSource}"

    # `init.lua`, not the directory: an empty or half-populated target passed a bare
    # -e test, linked successfully, and started nvim with no config and no warning.
    if [ ! -e "$WANT/init.lua" ]; then
      echo "sysinit-nvim: $WANT/init.lua does not exist." >&2
      echo "  Set sysinit.neovim.configPath to the neovim/config directory inside this" >&2
      echo "  repository's checkout on this host. It is deliberately NOT derived from" >&2
      echo "  programs.nh.flake; see neovim/options.nix." >&2
      exit 1
    fi

    if [ -L "$NVIM_DIR" ]; then
      # Already a symlink: retarget it only if it points somewhere else.
      if [ "$(readlink "$NVIM_DIR")" != "$WANT" ]; then
        $DRY_RUN_CMD ln -sfn "$WANT" "$NVIM_DIR"
      fi
    elif [ -e "$NVIM_DIR" ]; then
      # A real directory is here, which on any machine that ran an earlier
      # generation is the sysinit.nvim clone. Refuse rather than delete it: it may
      # hold commits that never reached a remote.
      echo "sysinit-nvim: $NVIM_DIR is a directory, not a symlink." >&2
      echo "  The config now lives at $WANT. Move the old checkout aside, then switch again:" >&2
      echo "    mv $NVIM_DIR $NVIM_DIR.pre-inline" >&2
      exit 1
    else
      $DRY_RUN_CMD ln -sfn "$WANT" "$NVIM_DIR"
    fi
  '';
}
