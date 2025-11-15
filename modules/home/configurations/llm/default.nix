{ ... }:
{
  imports = [
    ./config/claude.nix
    ./config/cursor-agent.nix
    ./config/goose.nix
    ./config/opencode.nix
    ./shared/execution.nix
  ];
}
