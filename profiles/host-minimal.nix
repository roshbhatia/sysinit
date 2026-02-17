{ pkgs, values, ... }:

{
  # Minimal macOS host profile
  # Desktop environment + minimal CLI tools
  # Development happens in Lima VMs, not on host

  imports = [
    # Import base first (but base is home-manager only, so we need to import it in home-manager section)
    # Import desktop profile (this has darwin system-level configs)
    ./desktop.nix
  ];

  # Lima runtime for VMs
  environment.systemPackages = with pkgs; [
    lima
  ];

  home-manager.users.${values.user.username} = {
    imports = [
      # Base profile
      ./base.nix

      # Terminal - currently WezTerm, will be Ghostty after PRD-04
      ../modules/home/configurations/wezterm

      # Minimal shell for host operations
      ../modules/home/configurations/zsh

      # Essential CLI tools
      ../modules/home/configurations/git

      # Desktop apps (Firefox, etc.)
      ../modules/darwin/home/firefox.nix
    ];

    home.packages = with pkgs; [
      # File navigation
      ripgrep
      fd
      bat
      eza
    ];
  };
}
