_:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = false; # Handled manually in zsh config
    enableNushellIntegration = true;
    options = [
      "--cmd cd"
    ];
  };
}
