{
  flake.modules.homeManager = {
    k9s = ./k9s.nix;
    kubectl = ./kubectl.nix;
  };
}
