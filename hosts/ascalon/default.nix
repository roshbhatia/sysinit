# Ascalon - Persistent Linux VM (starship from The Sun Eater)
# Golden image with full environment matching macOS
{ config, ... }:

{
  imports = [
    ../_base/nixos.nix
  ];

  # Persistent VM configuration
  networking.hostName = "ascalon";

  home-manager.users.${config.sysinit.user.username} = {
    imports = [
      # Ascalon gets language runtimes system-wide (same as macOS)
      ../../modules/home/packages/language-runtimes.nix
    ];

    # Packages already available via auto-imports:
    # - cli-tools.nix (all CLI utilities)
    # - dev-tools.nix (Docker, k8s, LSPs, formatters, etc.)
    # - language-managers.nix (rustup, uv, pipx)

    # Additional tools are in language-runtimes.nix imported above
  };
}
