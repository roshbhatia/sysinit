{
  lib,
  values,
  utils,
  inputs ? { },
  ...
}:

let
  # Optional companion repo — imported when the checkout exists on this machine.
  # builtins.pathExists returns false (not an error) in pure eval, so this guard
  # is safe on all machines; it evaluates correctly when built with --impure.
  extrasPath = /Users/roshan/github/personal/roshbhatia/sysinit.laurel/modules/home;
  extraHomeModules = lib.optionals (builtins.pathExists extrasPath) [ extrasPath ];
in

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
        ] ++ extraHomeModules;

        sysinit.git = values.git or { };
        sysinit.llm = values.llm or { };
        sysinit.theme =
          if (values ? theme) then
            values.theme
            // {
              # Strip readOnly `symbols` — it's derived in the module, not user-settable
              font = builtins.removeAttrs (values.theme.font or { }) [ "symbols" ];
            }
          else
            { };
      };
  };
}
