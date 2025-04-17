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
        "orbstack"
        "notion"
      ];
    };
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
      source = ./tests/01-nix-install-test.yaml;  # Using Nix path syntax
      destination = ".config/nix-test/nix-test.yaml";  # Using XDG config path
    }
  ];
}
