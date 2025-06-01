{ username, homeDirectory, ... }:
{
  users.users.${username}.home = homeDirectory;
}
