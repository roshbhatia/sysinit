# Host configurations
# Each host defines: system, platform, username, values
# Optional: config (path to host-specific nix module), isLima (for Lima VMs)
{
  overrides ? { },
}:

let
  # Default values shared across hosts
  defaults = {
    username = "rshnbhatia";

    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
    };

    theme = {
      appearance = "dark";
      colorscheme = "everforest";
      variant = "dark-soft";
      font.monospace = "TX-02";
      transparency = {
        opacity = 0.8;
        blur = 70;
      };
    };

    darwin = {
      tailscale.enable = true;
      homebrew.additionalPackages = {
        taps = [ ];
        brews = [ ];
        casks = [ ];
      };
    };
  };

  # Merge overrides into defaults
  common = defaults // overrides;
in
{
  # lv426 - Primary personal macOS workstation
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) theme git;
      user.username = common.username;
      hostname = "lv426";
      environment = {
        LIMA_INSTANCE = "nostromo";
      };
      darwin = common.darwin // {
        homebrew.additionalPackages = {
          taps = common.darwin.homebrew.additionalPackages.taps or [ ];
          brews = common.darwin.homebrew.additionalPackages.brews or [ ];
          casks = (common.darwin.homebrew.additionalPackages.casks or [ ]) ++ [
            "betterdiscord-installer"
            "discord"
            "ghostty"
            "steam"
          ];
        };
      };
    };
  };

  # nostromo - Personal NixOS Lima VM
  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    isLima = true;
    inherit (common) username;

    values = {
      inherit (common) theme git;
      user.username = common.username;
      hostname = "nostromo";
      isLima = true;
    };
  };
}
