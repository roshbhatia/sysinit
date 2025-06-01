{ username, ... }:
{
  nix = {
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
      substituters = [ "https://cache.nixos.org/" ];
      trusted-users = [
        "root"
        username
      ];
    };
    enable = false; # This is managed by determinate systems
  };
}
