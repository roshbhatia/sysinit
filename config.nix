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
        "blueutil"
        "go-task"
        "hashicorp/tap/packer"
        "qemu"
      ];
      casks = [
        "notion"
      ];
    };
  };

  wallpaper = {
    path = "wall/pain.jpeg";
  };

  pipx = {
    additionalPackages = [
      "mcp-proxy"
    ];
  };

  npm = {
    additionalPackages = [];
  };

  install = [
    {
      source = "modules/test/nix-install-test.yaml";
      destination = "/Users/rshnbhatia/.config/nix-test/nix-test.yaml";
    }
  ];
}
