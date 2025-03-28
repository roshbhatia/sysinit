{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    userName = "Roshan Bhatia";
    userEmail = "rshnbhatia@gmail.com";
    githubUser = "roshbhatia";
    credentialUsername = "roshbhatia";
  };

  homebrew = {
    additionalPackages = {
      taps = [];
      brews = [];
      casks = [
        "notion"
      ];
    };
  };

  wallpaper = {
    path = "wall/pain.jpeg";
  };

  # Files to install during system activation
  # Each entry must have a source and destination
  install = [
    # Test file for validation
    {
      source = toString modules/test/nix-install-test.yaml;
      destination = "~/.config/nix-test/nix-test.yaml";
    }
  ];
}