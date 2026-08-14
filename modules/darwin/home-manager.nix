{
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
    backupCommand = "rm -f";
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
          theme =
            if (values ? theme) then
              values.theme
              // {
                font = builtins.removeAttrs (values.theme.font or { }) [ "symbols" ];
              }
            else
              { };
        };
      };
  };
}
