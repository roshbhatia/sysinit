{ pkgs, config, ... }:

{
  imports = [
    ../shared/options/user.nix
    ../shared/options/theme.nix
    ./options.nix
    ../home/programs/git/options.nix

    ./aerospace.nix
    ./closed-lid-ssh.nix
    ./clamshell.nix
    ./borders.nix
    ./codesign.nix
    ./desktop.nix
    ./homebrew.nix
    ./keybindings.nix
    ./macos-tools.nix
    ./ollama.nix
    ./openssh.nix
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
