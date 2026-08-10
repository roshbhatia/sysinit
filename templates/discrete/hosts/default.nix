# Host configurations
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
        homebrew.additionalPackages = {
          taps = [ ];
          brews = [ ];
          casks = [ ];
        };
      };
    };
  };

}
