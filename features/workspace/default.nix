{
  flake.modules.homeManager.agentWorkspace = ./home.nix;
  perSystem =
    { pkgs, ... }:
    {
      packages.agent-workspace = pkgs.agent-workspace;
    };
}
