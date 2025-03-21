{ pkgs, lib, ... }: {
  # Homebrew configuration
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap";
    };
    taps = [
      "homebrew/cask"
      "homebrew/cask-fonts"
    ];
    brews = [
    ];
    casks = [
      "wezterm"
    ];
  };
}
