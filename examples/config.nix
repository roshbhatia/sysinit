# Example work configuration
{
  # User and system configuration
  user = {
    username = "roshanatwork";  # Work username
    hostname = "work-macbook";  # Work hostname
  };
  
  # Git configuration
  git = {
    # Global Git settings (required)
    userName = "Roshan Bhatia";
    userEmail = "roshan@work-domain.com";
    credentialUsername = "rbhatia";
    githubUser = "work-rbhatia";
    
    # Work-specific overrides (optional)
    workEmail = "roshan@work-domain.com";
    workGithubUser = "work-rbhatia";
    
    # Personal-specific overrides (optional)
    personalEmail = "personal@gmail.com";
    personalGithubUser = "personal-github";
  };

  # Additional Homebrew packages to install
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

  # Wallpaper configuration
  wallpaper = {
    path = "./wall/company-logo.jpg";
  };

  # Files to install in home directory
  install = [
    {
      source = "./work-configs/vpn-config";
      destination = ".config/vpn/config";
    }
    {
      source = "./work-configs/ssh-config";
      destination = ".ssh/config";
    }
  ];
}