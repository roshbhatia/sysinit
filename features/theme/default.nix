{
  flake.modules = {
    darwin.theme = ./darwin.nix;
    homeManager.theme = ./home.nix;
    nixos.theme = ./nixos.nix;
    nixOnDroid.grayscaleTerminal = ./nix-on-droid.nix;
  };
}
