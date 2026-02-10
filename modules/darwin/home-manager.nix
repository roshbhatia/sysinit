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
        home.enableNixpkgsReleaseCheck = false;
        nixpkgs.config.permittedInsecurePackages = [
          "olm-3.2.16"
        ];
        imports = [
          ../home
          ./home
        ];
      };
  };
}
