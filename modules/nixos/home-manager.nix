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
          # Shared module options at home-manager level
          ../options/theme.nix
          ../options/packages.nix
          ../options/llm.nix
          ../home/programs/git/options.nix

          ../home

          # NixOS (persistent VM) gets language runtimes like macOS
          ../home/packages/language-runtimes.nix
        ];

        sysinit.git = values.git;
      };
  };
}
