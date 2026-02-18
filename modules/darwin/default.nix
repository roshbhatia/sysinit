{ pkgs, config, ... }:

{
  imports = [
    # Shared modules (available at system level)
    ../options/user.nix
    ../options/darwin.nix
    ../options/theme.nix
    ../home/programs/git/options.nix

    # System configurations
    ./aerospace.nix
    ./borders.nix
    ./desktop.nix
    ./homebrew.nix
    ./macos-tools.nix
    ./ollama.nix
    ./security.nix
    ./sketchybar.nix
    ./stylix.nix
    ./system.nix
    ./tailscale.nix
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
