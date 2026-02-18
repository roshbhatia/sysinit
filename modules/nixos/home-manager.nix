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
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home

          # NixOS (persistent VM) gets language runtimes like macOS
          ../home/packages/language-runtimes.nix
        ];

        # Disable desktop-related stylix targets for headless NixOS
        stylix.targets = {
          gnome.enable = false;
          gtk.enable = false;
        };

        sysinit.git = values.git;
      };
  };
}
