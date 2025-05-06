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
    "jandedobbeleer/oh-my-posh"
    "homebrew/bundle"
    "homebrew/cask"
    "homebrew/core"
    "homebrew/services"
    "mediosz/tap"
    "noahgorstein/tap"
    "nikitabobko/tap"
    "FelixKratz/formulae"
    "sandreas/tap"
  ];

  baseBrews = [
    "argocd"
    "ansible"
    "bcrypt"
    "caddy"
    "colima"
    "direnv"
    "eza"
    "fd"
    "glow"
    "gum"
    "git-filter-repo"
    "gettext"
    "helix"
    "helm"
    "helm-ls"
    "jandedobbeleer/oh-my-posh/oh-my-posh"
    "kubectl"
    "kubecolor"
    "k9s"
    "lazygit"
    "libgit2"
    "luajit"
    "luarocks"
    "m4b-tool"
    "nushell"
    "pipx"
    "prettierd"
    "python"
    "python@3.11"
    "ripgrep"
    "rust"
    "screenresolution"
    "shellcheck"
    "socat"
    "sshpass"
    "tailscale"
    "taplo"
    "go-task"
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
