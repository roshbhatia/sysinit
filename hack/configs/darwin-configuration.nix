{ pkgs, ... }:
{
  system.configurationRevision = null;
  system.stateVersion = 4;
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.config.allowUnfree = true;
  nix.enable = false;
  
  nix.settings = {
    trusted-users = [ "root" "@wheel" ];
    experimental-features = [ "nix-command" "flakes" ];
  };

  programs.zsh.enable = true;

  environment.systemPackages = with pkgs; [
    git
    curl
    libgit2
  ];
  
  security.pam.services.sudo_local.touchIdAuth = true;
}
