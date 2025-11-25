{ values, ... }:
{
  nix.enable = false;

  system = {
    defaults.LaunchServices.LSQuarantine = false;
    primaryUser = values.user.username;
    spaces.spans-display = true;
    stateVersion = 4;
  };
}
