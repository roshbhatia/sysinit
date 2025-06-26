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
      taps = [ "hashicorp/tap" ];
      brews = [
        "blueutil"
        "hashicorp/tap/packer"
        "tailscale"
        "qemu"
      ];
      casks = [
        "betterdiscord-installer"
        "discord"
        "notion"
        "steam"
        "supercollider"
        "vnc-viewer"
      ];
    };
  };
}
