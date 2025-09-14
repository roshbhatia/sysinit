{
  pkgs,
  ...
}:

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

  security.pam.services.sudo_local.touchIdAuth = true;
}
