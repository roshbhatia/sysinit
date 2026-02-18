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
  # yourhostname - Primary macOS workstation
  yourhostname = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) theme git;
      user.username = common.username;
      hostname = "yourhostname";
      darwin = common.darwin // {
        homebrew.additionalPackages = {
          taps = common.darwin.homebrew.additionalPackages.taps or [ ];
          brews = common.darwin.homebrew.additionalPackages.brews or [ ];
          casks = (common.darwin.homebrew.additionalPackages.casks or [ ]);
        };
      };
    };
  };

  # yourhostname-vm - NixOS Lima VM (optional)
  # Uncomment to enable Lima VM configuration
  # your-nixos-hostname = {
  #   system = "aarch64-linux";
  #   platform = "linux";
  #   isLima = true;
  #   inherit (common) username;
  #
  #   values = {
  #     inherit (common) theme git;
  #     user.username = common.username;
  #     hostname = "your-nixos-hostname";
  #   };
  # };
}
