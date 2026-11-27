{
  flake.modules.homeManager.review = ./home.nix;
  perSystem =
    { pkgs, ... }:
    {
      packages = { inherit (pkgs) agent-diff agent-review-link; };
    };
}
