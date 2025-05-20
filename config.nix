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
    enable = true;
    additionalPackages = {
      taps = [
        "hashicorp/tap"
      ];
      brews = [
        "blueutil"
        "hashicorp/tap/packer"
        "tailscale"
        "qemu"
      ];
      casks = [
        "discord"
        "orbstack"
        "notion"
        "vnc-viewer"
      ];
    };
  };

  pipx = {
    additionalPackages = [
      "mcp-proxy"
    ];
  };

  npm = {
    additionalPackages = [ ];
  };
}
