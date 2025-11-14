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
      inherit utils values;
    };

    users.${values.user.username} =
      {
        pkgs,
        lib,
        config,
        ...
      }:
      import ../home {
        inherit
          config
          pkgs
          lib
          utils
          values
          ;
      };
  };
}
