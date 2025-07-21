{
  username,
  system,
  ...
}:
{
  nix = {
    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
        "no-url-literals"
      ];
      gc = {
        automatic = true;
        interval = {
          Hour = 5;
          Minute = 0;
        };
        options = "--delete-older-than 7d";
      };
      optimise = {
        automatic = true;
        interval = {
          Hour = 6;
          Minute = 0;
        };
      };
      substituters = [ "https://cache.nixos.org/" ];
      trusted-users = [
        "root"
        username
      ];
    };
    enable = false; # This is managed by determinate systems. Not sure if the above is applicable?
  };

  nixpkgs = {
    hostPlatform = system;
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowInsecure = false;
      allowUnsupportedSystem = true;
    };
  };
}

