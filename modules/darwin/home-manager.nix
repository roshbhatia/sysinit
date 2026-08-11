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
    # Delete the file in the way rather than renaming it to `<name>.backup`.
    #
    # `backupFileExtension` left one dead file per target that this repository
    # ever took over, and nothing removes them: `~/.codex/config.toml.backup`
    # survived from 2026-07-28. Dropping the option instead is not the fix.
    # `modules/files/check-link-targets.sh` falls through to
    # `collisionErrors+=("Existing file ... would be clobbered")` when neither a
    # command nor an extension is set, so the switch would abort rather than
    # overwrite.
    #
    # `backupCommand` is checked before `backupFileExtension` in both
    # check-link-targets.sh and files.nix, so the two must not both be set: the
    # extension would read as live and never run.
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
