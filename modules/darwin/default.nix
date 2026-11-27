{ pkgs, config, ... }:

{
  imports = [
    ../shared/options/user.nix
    ../shared/codex-hooks.nix
    ./options.nix
    ../../features/git/options.nix

    ./rift.nix
    ./clamshell.nix
    ./borders.nix
    ./codesign.nix
    ./defaults-incremental.nix
    ./desktop.nix
    ./homebrew.nix
    ./keybindings.nix
    ./log-retention.nix
    ./macos-tools.nix
    ./ollama.nix
    ../../features/ssh/darwin.nix
    ./security.nix
    ./sketchybar.nix
    ../../features/theme/darwin.nix
    ./system.nix
    ../../features/tailscale/service.nix
  ];

  sysinit.darwin.defaults.remove."org.mozilla.firefox" = [
    "HomepageURL"
    "NewTabURL"
  ];

  system.build.applications = pkgs.buildEnv {
    name = "system-applications";
    paths = config.environment.systemPackages;
    pathsToLink = [ "/Applications" ];
  };
}
