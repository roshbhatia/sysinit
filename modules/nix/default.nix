{
  username,
  system,
  ...
}:
{
  nix = {
    enable = false;
    settings = {
      experimental-features = [
        "flakes"
        "nix-command"
        "no-url-literals"
      ];
      substituters = [
        "https://cache.nixos.org/"
      ];
      trusted-users = [
        "root"
        username
      ];
    };

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
