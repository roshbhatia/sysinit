{
  flake.modules = {
    nixos.systemUpgrade = ./nixos.nix;
    darwin.systemUpgrade = ./darwin.nix;
  };
}
