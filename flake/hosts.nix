common:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;
    values = common.values // {
      darwin = {
        dock.entries = common.values.darwin.dock.entries ++ [
          { path = "/Applications/Messages.app"; }
          { path = "/Applications/Discord.app"; }
        ];
        homebrew.additionalPackages.casks = [
          "betterdiscord-installer"
          "calibre"
          "discord"
          "steam"
        ];
      };
    };
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    inherit (common) username;
    values = common.values // {
      theme = {
        colorscheme = "gruvbox";
        variant = "dark";
        font = {
          monospace = "MonaspiceKr Nerd Font Mono";
        };
      };
    };
  };
}
