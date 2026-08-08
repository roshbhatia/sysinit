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
  # `mkOutOfStoreSymlink`, not a plain `source`: a plain source copies the tree
  # into the store, and lazy.nvim writes `lazy-lock.json` into the config root,
  # which a read-only store tree cannot accept. It would also put a keymap edit
  # behind a switch. Out of store, `~/.config/nvim` resolves through the store
  # symlink to the working tree, so writes land in git where their drift is
  # visible and the edit loop stays "edit, restart nvim".
  #
  # Declarative rather than a hand-rolled `ln -sfn` in an activation script:
  # home-manager then owns the link's lifetime, so removing this module removes
  # the symlink. The activation script left it behind.
  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink configSource;

  # What stays imperative: two preconditions home-manager cannot express.
  #
  # Ordered before linkGeneration so it reports the problem instead of letting
  # the link step fail on it. Same reasoning as llm/default.nix: the DAG decides
  # this, not the alphabetical order of entry names.
  home.activation.sysinit-nvim-preflight =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        NVIM_DIR="${nvimDir}"
        WANT="${configSource}"

        # `init.lua`, not the directory: an empty or half-populated target passed a bare
        # -e test, linked successfully, and started nvim with no config and no warning.
        # mkOutOfStoreSymlink does not check its target either, so without this the
        # same silent failure returns as a dangling symlink.
        if [ ! -e "$WANT/init.lua" ]; then
          echo "sysinit-nvim: $WANT/init.lua does not exist." >&2
          echo "  Set sysinit.neovim.configPath to the neovim/config directory inside this" >&2
          echo "  repository's checkout on this host. It is deliberately NOT derived from" >&2
          echo "  programs.nh.flake; see neovim/options.nix." >&2
          exit 1
        fi

        # A real directory here, on any machine that ran an earlier generation, is the
        # sysinit.nvim clone. home-manager would refuse to clobber it too, but it would
        # not say that the contents may be commits that never reached a remote.
        if [ -e "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
          echo "sysinit-nvim: $NVIM_DIR is a directory, not a symlink." >&2
          echo "  The config now lives at $WANT. Move the old checkout aside, then switch again:" >&2
          echo "    mv $NVIM_DIR $NVIM_DIR.pre-inline" >&2
          exit 1
        fi
      '';
}
