{
  flake.modules.homeManager = {
    nushell = ./home.nix;
    nushellInteractive = ./interactive.nix;
  };
}
