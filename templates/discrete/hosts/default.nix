{
  overrides ? { },
}:

let
  defaults = {
    username = "yourusername";

    git = {
      name = "Your Name";
      email = "your.email@example.com";
      username = "yourgithub";
    };
  };

  common = defaults // overrides;
in
{
  yourhostname = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      inherit (common) git;
      user.username = common.username;
      hostname = "yourhostname";

      theme = {
        appearance = "dark";
        # A name from `pkgs.base16-schemes`, or a handmade base00..base0F set.
        base16Scheme = "everforest";
        font.monospace = "TX-02";
        transparency = {
          opacity = 0.8;
          blur = 70;
        };
      };

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
