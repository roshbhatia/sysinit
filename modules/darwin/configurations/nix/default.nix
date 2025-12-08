{ values, ... }:
{
  nix = {
    settings = {
      trusted-users = [
        "root"
        "@admin"
        values.user.username
      ];
    };
  };
}
