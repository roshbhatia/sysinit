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
        pkgs,
        config,
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

        stylix = {
          enable = true;
          autoEnable = true;
          image = lib.mkDefault (pkgs.fetchurl {
            url = "https://wallpapercave.com/wp/wp12329549.png";
            sha256 = "sha256-9R3cDgd1VslCF6mG6jBO64MEdRjCGzWE4m/dAjEixzk=";
          });
          base16Scheme = lib.mkDefault "${pkgs.base16-schemes}/share/themes/${config.sysinit.theme.base16Scheme}.yaml";
          polarity = config.sysinit.theme.appearance;
        };

        sysinit.git = values.git or { };
        sysinit.theme =
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
}
