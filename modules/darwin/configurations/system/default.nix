{ values, ... }:
{
  nix.enable = false;

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = values.user.username;
    stateVersion = 4;
  };
}
