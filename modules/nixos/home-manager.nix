{
  lib,
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
        imports = [
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home
        ]
        ++ lib.optionals values.isDesktop [
          ./home/desktop.nix
          ./home/launcher.nix
          ./home/streaming.nix
          ../home/programs/firefox.nix
          ../home/programs/obsidian.nix
        ];

        home.homeDirectory = "/home/${values.user.username}";

        sysinit = {
          git = values.git or { };
          llm = values.llm or { };
          theme = values.theme or { };
        };
      };
  };
}
