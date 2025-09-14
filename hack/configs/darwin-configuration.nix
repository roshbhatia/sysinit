{ pkgs, ... }:
{
  system.configurationRevision = null;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;

  environment.systemPackages = with pkgs; [
    git
    curl
    findutils
    libgit2
    coreutils
  ];

  environment.extraInit = ''
    export PATH="${pkgs.coreutils}/bin:${pkgs.findutils}/bin:$PATH"
    # Ensure GNU readlink is available for compatibility
    alias readlink="${pkgs.coreutils}/bin/readlink"
  '';

  security.pam.services.sudo_local.touchIdAuth = true;
}
