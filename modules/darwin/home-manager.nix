{
  pkgs,
  values,
  profile ? "workstation",
  theme ? true,
  inputs ? { },
  ...
}:

{
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    backupCommand = "${pkgs.trash-cli}/bin/trash-put";
    extraSpecialArgs = {
      inherit
        values
        inputs
        profile
        theme
        ;
    };

    users.${values.user.username} =
      {
        ...
      }:
      {
        home.enableNixpkgsReleaseCheck = false;
        imports = [
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home

          ./home
        ];

        sysinit = {
          git = values.git or { };
          llm = values.llm or { };
          theme = values.theme or { };
        };
      };
  };
}
