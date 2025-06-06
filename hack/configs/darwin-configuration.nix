{ pkgs, ... }:
{
  system.configurationRevision = null;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    substituters = "https://cache.nixos.org/";
    trusted-users = [
      "*"
    ];
    warn-dirty = false;
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    findutils
    libgit2
  ];

  environment.extraInit = ''
    export PATH="${pkgs.findutils}/bin:$PATH"
  '';

  security.pam.services.sudo_local.touchIdAuth = true;
}
