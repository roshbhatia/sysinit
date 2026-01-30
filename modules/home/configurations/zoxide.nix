_:

{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  home.sessionVariables = {
    _ZO_FZF_OPTS = builtins.concatStringsSep " " [
      "--style=minimal"
      "--layout=reverse"
      "--height=80%"
      "--info=inline"
      "--scheme=history"
      "--bind=resize:refresh-preview"
      "--bind=ctrl-/:toggle-preview"
    ];
  };
}
