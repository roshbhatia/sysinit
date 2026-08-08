{
  lib,
  config,
  ...
}:
let
  configSource = config.sysinit.neovim.configPath;
  nvimDir = "${config.xdg.configHome}/nvim";
in
{
  imports = [ ./options.nix ];

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink configSource;

  home.activation.sysinit-nvim-preflight =
    lib.hm.dag.entryBetween [ "linkGeneration" ] [ "writeBoundary" ]
      ''
        NVIM_DIR="${nvimDir}"
        WANT="${configSource}"

        if [ ! -e "$WANT/init.lua" ]; then
          echo "sysinit-nvim: $WANT/init.lua does not exist." >&2
          echo "  Set sysinit.neovim.configPath to the neovim/config directory inside this" >&2
          echo "  repository's checkout on this host. It is deliberately NOT derived from" >&2
          echo "  programs.nh.flake; see neovim/options.nix." >&2
          exit 1
        fi

        if [ -e "$NVIM_DIR" ] && [ ! -L "$NVIM_DIR" ]; then
          echo "sysinit-nvim: $NVIM_DIR is a directory, not a symlink." >&2
          echo "  The config now lives at $WANT. Move the old checkout aside, then switch again:" >&2
          echo "    mv $NVIM_DIR $NVIM_DIR.pre-inline" >&2
          exit 1
        fi
      '';
}
