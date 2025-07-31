{
  username,
  ...
}:
{
  nix.enable = false;

  system = {
    primaryUser = username;
    stateVersion = 4;
  };
}

