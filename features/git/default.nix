{
  flake.modules.homeManager = {
    git = ./home.nix;
    gitIdentity = ./identity.nix;
  };
}
