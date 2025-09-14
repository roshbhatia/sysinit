{ pkgs, ... }:

{
  system.configurationRevision = null;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    coreutils
    curl
    findutils
    git
    libgit2
  ];

  environment.variables.PATH = [
    "${pkgs.coreutils}/bin"
    "${pkgs.findutils}/bin"
    "$PATH"
  ];

  security.pam.services.sudo_local.touchIdAuth = true;
}
