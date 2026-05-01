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
        imports = [
          # Shared module options at home-manager level
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          # Cross-platform home modules
          ../home

          # Darwin-specific home modules
          ./home
        ];

        sysinit.git = values.git or { };
        sysinit.theme =
          if (values ? theme) then
            values.theme // {
              # Strip readOnly `symbols` — it's derived in the module, not user-settable
              font = builtins.removeAttrs (values.theme.font or { }) [ "symbols" ];
            }
          else
            { };
      };
  };
}
