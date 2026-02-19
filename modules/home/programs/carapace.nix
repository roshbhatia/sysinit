{
  ...
}:

{
  programs.carapace = {
    enable = true;

    enableFishIntegration = true;
    enableNushellIntegration = true;
    enableZshIntegration = true;
  };

  # Enable carapace bridges to fallback to native shell completions
  # This allows carapace to use zsh/fish/bash completions when it doesn't have native support
  home.sessionVariables = {
    CARAPACE_BRIDGES = "zsh,fish,bash,inshellisense";
  };
}
