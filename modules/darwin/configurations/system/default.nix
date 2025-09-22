{ values, ... }:
{
  nix.enable = false;

  system = {
    primaryUser = values.user.username;
    stateVersion = 4;
    defaults.LaunchServices.LSQuarantine = false;
  };
}
