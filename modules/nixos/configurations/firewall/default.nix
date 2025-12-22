{
  # Firewall is disabled by default in networking/default.nix via lib.mkDefault false
  # This allows all traffic - fine for internal/development setup
  # If needed in future, enable via: networking.firewall.enable = true;
}
