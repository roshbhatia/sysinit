{ ... }:

{
  imports = [
    ./boot.nix
    ./display.nix
    ./gpu.nix
    ./audio.nix
    # ./gaming.nix  # Not supported on aarch64
    ./shell.nix
  ];
}
