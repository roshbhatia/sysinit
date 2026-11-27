{
  perSystem =
    { pkgs, ... }:
    {
      packages.agent-workspace = import ./package.nix { inherit pkgs; };
    };
}
