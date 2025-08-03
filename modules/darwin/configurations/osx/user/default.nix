{ values, ... }:
{
  users.users.${values.user.username}.home = "/Users/${values.user.username}";
}
