{ pkgs, lib, config, enableHomebrew ? true, username, inputs, userConfig ? {}, ... }:

let
  additionalTaps = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? taps
                  then userConfig.homebrew.additionalPackages.taps
                  else [];

  additionalBrews = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? brews
                   then userConfig.homebrew.additionalPackages.brews
                   else [];

  additionalCasks = if userConfig ? homebrew && userConfig.homebrew ? additionalPackages && userConfig.homebrew.additionalPackages ? casks
                   then userConfig.homebrew.additionalPackages.casks
                   else [];

  baseTaps = [
    "FelixKratz/formulae"
    "homebrew/bundle"
    "homebrew/cask"
    "homebrew/core"
    "homebrew/services"
    "jandedobbeleer/oh-my-posh"
    "mediosz/tap"
    "nikitabobko/tap"
    "noahgorstein/tap"
    "sandreas/tap"
  ];

  baseBrews = [
    "ansible"
    "argocd"
    "bcrypt"
    "caddy"
    "colima"
    "direnv"
    "eza"
    "fd"
    "gettext"
    "git-filter-repo"
    "glow"
    "go-task"
    "gum"
    "helix"
    "helm-ls"
    "helm"
    "imagemagick"
    "jandedobbeleer/oh-my-posh/oh-my-posh"
    "k9s"
    "kubecolor"
    "kubectl"
    "lazygit"
    "libgit2"
    "luajit"
    "luarocks"
    "lynx"
    "nushell"
    "peterldowns/tap/nix-search-cli"
    "pipx"
    "prettierd"
    "python"
    "python@3.11"
    "pngpaste"
    "ripgrep"
    "rust"
    "screenresolution"
    "shellcheck"
    "socat"
    "sshpass"
    "tailscale"
    "taplo"
    "yazi"
  ];

  baseCasks = [
    "1password-cli"
    "alt-tab"
    "discord"
    "firefox"
    "font-hack-nerd-font"
    "font-symbols-only-nerd-font"
    "jordanbaird-ice"
    "keycastr"
    "loop"
    "obsidian"
    "raycast"
    "slack"
    "visual-studio-code@insiders"
    "vnc-viewer"
    "wezterm"
  ];

  allTaps = baseTaps ++ additionalTaps;
  allBrews = baseBrews ++ additionalBrews;
  allCasks = baseCasks ++ additionalCasks;
in
{
  nix-homebrew = {
    enable = enableHomebrew;
    enableRosetta = true;
    user = username;
    autoMigrate = true;
    taps = {
      "homebrew/homebrew-core" = inputs.homebrew-core;
      "homebrew/homebrew-cask" = inputs.homebrew-cask;
    };
    mutableTaps = true;
  };

  homebrew = {
    enable = enableHomebrew;
    onActivation = {
      autoUpdate = true;
      upgrade = true;
      cleanup = "zap";
    };
    global = {
      brewfile = true;
      lockfiles = true;
    };

    taps = allTaps;
    brews = allBrews;
    casks = allCasks;
  };
}
