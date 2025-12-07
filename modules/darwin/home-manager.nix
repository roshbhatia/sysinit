{
  values,
  utils,
  pkgs,
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
          ./home-specific # Darwin-specific configurations
        ];

        home.packages = with pkgs; [
          wezterm
        ];
      };
  };
}
