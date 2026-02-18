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
          ../options/theme.nix
          ../options/llm.nix
          ../home/programs/git/options.nix

          ../home

          # macOS gets language runtimes system-wide
          ../home/packages/language-runtimes.nix
        ];

        sysinit.git = values.git;
      };
  };
}
