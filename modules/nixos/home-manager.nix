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
          ../shared/options/theme.nix
          ../home/programs/llm/options.nix
          ../home/programs/git/options.nix

          ../home
        ]
        ++ lib.optionals values.isDesktop [
          ./home/desktop.nix
          ./home/streaming.nix
          ../home/programs/firefox.nix
          ../home/programs/obsidian.nix
        ];

        home.homeDirectory = "/home/${values.user.username}";

        sysinit = {
          git = values.git or { };
          llm = values.llm or { };
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
