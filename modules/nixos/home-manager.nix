{
  values,
  customUtils ? null,
  inputs ? { },
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
      inherit utils values inputs;
    };
    sharedModules = [
      (inputs.stylix.homeManagerModules.stylix or { })
    ];

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
