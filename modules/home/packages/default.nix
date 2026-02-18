{
  imports = [
    # Legacy monolithic package list (will be removed after migration)
    ./nix.nix

    # Categorized package lists
    ./cli-tools.nix
    ./dev-tools.nix
    ./language-managers.nix
    # NOTE: language-runtimes.nix is NOT imported by default
    # It's only imported by macOS hosts and persistent VM

    # Tool-specific configurations
    ./cargo.nix
    ./gh.nix
    ./go.nix
    ./npm.nix
    ./pipx.nix
    ./uvx.nix
    ./vet.nix
    ./yarn.nix
  ];
}
