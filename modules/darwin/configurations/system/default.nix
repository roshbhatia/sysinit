{ values, ... }:
{
  system = {
    primaryUser = values.user.username;
    stateVersion = 4;
  };
}
