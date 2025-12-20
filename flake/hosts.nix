sharedValues:

{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    username = "rshnbhatia";
    values = sharedValues // {
      darwin.homebrew.additionalPackages.casks = [
        "discord"
        "betterdiscord-installer"
        "calibre"
      ];
    };
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    username = "rshnbhatia";
    values = sharedValues // {
      theme = {
        colorscheme = "gruvbox";
        variant = "dark";
        font = {
          monospace = "MonaspiceKr Nerd Font Mono";
        };
      };
      tailscale = {
        enable = true;
      };
    };
  };
}
