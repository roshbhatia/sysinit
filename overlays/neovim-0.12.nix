{ ... }:

final: prev: {
  # Use neovim 0.12.0 from nixpkgs-unstable directly (no nightly overlay needed)
  neovim-unwrapped = prev.neovim-unwrapped;
}
