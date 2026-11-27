{
  flake.modules = {
    darwin.tailscale = ./service.nix;
    nixos.tailscale = ./service.nix;
  };
}
