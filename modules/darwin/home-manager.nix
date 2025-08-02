{
  username,
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

    users.${username} = import ../home {
      inherit username values utils;
    };
  };
}
