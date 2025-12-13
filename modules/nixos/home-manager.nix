{
  values,
  customUtils ? null,
  ...
}:

let
  utils = customUtils;
in
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
          ../home
          ./home
        ];
      };
  };
}
