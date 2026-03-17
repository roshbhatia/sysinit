{
  lib,
  pkgs,
  values,
  utils,
  inputs ? { },
  stylix,
  ...
}:

let
  themes = import ../lib/theme.nix { inherit lib; };
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
        imports = [
          # Shared module options at home-manager level
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home
        ]
        ++ lib.optionals (values.isDesktop) [
          ./home/desktop.nix
          ../home/programs/qutebrowser
        ];

        # NixOS systems use the nix-managed home directory
        home.homeDirectory =
          if values.isLima then
            lib.mkForce "/home/${values.user.username}.linux"
          else
            "/home/${values.user.username}";

        sysinit.git = values.git or { };
        sysinit.theme =
          if (values ? theme) then
            {
              appearance = values.theme.appearance or null;
              colorscheme = values.theme.colorscheme;
              variant = values.theme.variant;
              font.monospace = values.theme.font.monospace or null;
              transparency = values.theme.transparency or { };
            }
          else
            { };
      };
  };
}
