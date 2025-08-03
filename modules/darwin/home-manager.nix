{
  values,
  utils,
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit utils;
    };

    users.${values.user.username} = import ../home {
      username = values.user.username;
      inherit values utils;
    };
  };
}
