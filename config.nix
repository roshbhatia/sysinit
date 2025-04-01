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
      taps = [
        "hashicorp/tap"
      ];
      brews = [
        "hashicorp/tap/packer"
      ];
      casks = [
        "iterm2"
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
      source = "modules/test/nix-install-test.yaml";
      destination = "/Users/rshnbhatia/.config/nix-test/nix-test.yaml";
    }
    
    # Example of a custom file installation
    # {
    #   source = "examples/work-configs/ssh-config";
    #   destination = "/Users/rshnbhatia/.ssh/config";
    # }
  ];
}