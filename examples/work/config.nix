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
    path = toString ./wallpaper/images/company-logo.jpg;  # Path relative to flake root
  };

  # Files to install during system activation (optional)
  # Each entry must have source and destination paths
  install = [
    # Work config files
    {
      source = toString ./work-configs/ssh-config;
      destination = ~/.ssh/config;
    },
    {
      source = toString ./work-configs/vpn-config;
      destination = toString ~/.config/vpn/config;
    }
  ];
}