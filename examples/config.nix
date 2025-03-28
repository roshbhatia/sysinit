# Example work configuration
{
  # User and system configuration
  user = {
    username = "roshanatwork";  # Work username
    hostname = "work-macbook";  # Work hostname
  };
  
  # Git configuration - all fields are required
  git = {
    userName = "Roshan Bhatia";
    userEmail = "roshan@work-domain.com";
    githubUser = "work-rbhatia";
    credentialUsername = "rbhatia";
    
    # Optional git configurations
    # personalEmail = "personal@gmail.com";
    # workEmail = "roshan@work-domain.com";
    # personalGithubUser = "personal-github";
    # workGithubUser = "work-rbhatia";
  };

  # Additional Homebrew packages to install (optional)
  homebrew = {
    additionalPackages = {
      taps = [
        "company/internal"
      ];

      brews = [
        "work-specific-tool"
        "company-cli"
      ];

      casks = [
        "company-chat-app"
        "company-vpn"
        "microsoft-outlook"
        "microsoft-teams"
        "zoom"
      ];
    };
  };

  # Wallpaper configuration (optional)
  wallpaper = {
    path = "./wall/company-logo.jpg";  # Path relative to flake root
  };

  # Files to install during system activation (optional)
  # Each entry must have source and destination paths
  install = [
    # Test file for validation
    {
      source = "modules/test/nix-install-test.yaml";
      destination = "/Users/roshanatwork/.config/nix-test/nix-test.yaml";
    },
    
    # Work-specific configuration files
    {
      source = "./work-configs/ssh-config";
      destination = "/Users/roshanatwork/.ssh/config";
    },
    {
      source = "./work-configs/vpn-config";
      destination = "/Users/roshanatwork/.config/vpn/config";
    }
  ];
}