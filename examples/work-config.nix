# Example work configuration
{
  # User and system configuration
  user = {
    username = "roshanatwork";  # Work username
    hostname = "work-macbook";  # Work hostname
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
    path = "./wall/company-logo.jpg";  # Company wallpaper
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