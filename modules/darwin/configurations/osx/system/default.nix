{
  username,
  homeDirectory,
  ...
}: {
  system = {
    primaryUser = username;
    stateVersion = 4;
  };

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
    enable = false;
  };

  users.users.${username}.home = homeDirectory;
}
