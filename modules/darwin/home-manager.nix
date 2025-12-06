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
        ...
      }:
      {
        imports = [
          ../home # Cross-platform configurations
          ./home # Darwin-specific configurations
        ];
      };
  };
}
