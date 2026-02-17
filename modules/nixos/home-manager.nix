{
  values,
  utils,
  inputs ? { },
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit utils values inputs;
    };

    users.${values.user.username} =
      {
        ...
      }:
      {
        imports = [
          ../home
          ./home
          # Inline module to set sysinit values from common.nix values
          {
            config.sysinit.git = values.git;
          }
        ];
      };
  };
}
