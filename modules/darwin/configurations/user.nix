{
  values,
  ...
}:

{
  # macOS user home directory - platform-specific
  # (nix-darwin users.users.X.home must be set to /Users/X on macOS)
  users.users.${values.user.username}.home = "/Users/${values.user.username}";
}
