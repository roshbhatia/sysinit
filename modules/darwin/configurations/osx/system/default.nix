{ username, ... }:
{
  system = {
    primaryUser = username;
    stateVersion = 4;
  };
}
