# Host configurations
# Each host defines: system, platform, username, values
# Optional: config (path to host-specific nix module), isLima (for Lima VMs)
{
  overrides ? { },
}:

let
  # Default values shared across hosts
  defaults = {
    username = "yourusername";

    git = {
      name = "Your Name";
      email = "your.email@example.com";
      username = "yourgithub";
    };
  };

  # Merge overrides into defaults
  common = defaults // overrides;
in
{
  # yourhostname - Primary macOS workstation
  yourhostname = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) git;
      user.username = common.username;
      hostname = "yourhostname";

      # Customize theme, transparency, and other settings here
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

      # Darwin-specific settings
      darwin = {
        tailscale.enable = true;
        homebrew.additionalPackages = {
          taps = [ ];
          brews = [ ];
          casks = [ ];
        };
      };
    };
  };

  # your-nixos-hostname - NixOS Lima VM (optional)
  # Uncomment to enable Lima VM configuration
  # your-nixos-hostname = {
  #   system = "aarch64-linux";
  #   platform = "linux";
  #   isLima = true;
  #   inherit (common) username;
  #
  #   values = {
  #     inherit (common) git;
  #     user.username = common.username;
  #     hostname = "your-nixos-hostname";
  #
  #     # Customize theme and other settings
  #     theme = {
  #       appearance = "dark";
  #       colorscheme = "everforest";
  #       variant = "dark-soft";
  #       font.monospace = "TX-02";
  #       transparency = {
  #         opacity = 0.8;
  #         blur = 70;
  #       };
  #     };
  #   };
  # };
}
