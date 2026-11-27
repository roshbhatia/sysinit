{
  perSystem =
    { pkgs, ... }:
    {
      packages.agent-diff = import ./package.nix { inherit pkgs; };
    };
}
