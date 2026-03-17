{
  lib,
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
          inputs.stylix.homeManagerModules.stylix
        ]
        ++ lib.optionals (values.desktop or false) [
          ./home/desktop.nix
          ../home/programs/firefox
        ];

        # NixOS systems use the nix-managed home directory
        home.homeDirectory =
          if (values.lima or false) then
            lib.mkForce "/home/${values.user.username}.linux"
          else
            lib.mkForce "/home/${values.user.username}";

        sysinit = {
          git = values.git or { };
          theme =
            if (values ? theme) then
              {
                base16Scheme = values.theme.base16Scheme or "catppuccin-mocha";
                appearance = values.theme.appearance or "dark";
                font.monospace = values.theme.font.monospace or "TX-02";
                transparency = values.theme.transparency or { };
              }
            else
              { };
        };
      };
  };
}
