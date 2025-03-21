{ pkgs, lib, ... }: {
  # Packages installed to the user profile
  home.packages = with pkgs; [
    # CLI tools
    atuin
    btop
    fd
    fzf
    gh
    git
    jq
    k9s
    macchina
    ripgrep
    starship
    tree
    zsh
  ];
}
