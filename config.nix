{
  # User and system configuration
  user = {
    username = "rshnbhatia";  # Default username
    hostname = "lv426";      # Default hostname
  };

  # Additional Homebrew packages to install
  homebrew = {
    additionalPackages = {
      taps = [
        # Add additional taps here
        # Example: "user/repo"
      ];

      brews = [
        # Add additional brew packages here
        # Example: "package-name"
      ];

      casks = [
        # Add additional cask applications here
        # Example: "app-name"
      ];
    };
  };

  # Wallpaper configuration
  wallpaper = {
    path = "./wall/mvp2.jpg";  # Default wallpaper path
  };

  # Files to install in home directory
  install = [
    # Example file installation
    # {
    #   source = "./path/to/source/file";
    #   destination = ".config/destination/file";
    # }
  ];
}