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
      inherit utils values;
    };

    users.${username} = import ../home {
      inherit username values utils;
      pkgs = null; # Will be provided by home-manager
    };
  };
}
