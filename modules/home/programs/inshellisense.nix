{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.inshellisense ];

  # Zsh integration
  programs.zsh.initExtra = lib.mkAfter ''
    # Initialize inshellisense if available
    if command -v is &>/dev/null; then
      eval "$(is init zsh)"
    fi
  '';

  # Fish integration
  programs.fish.interactiveShellInit = lib.mkAfter ''
    # Initialize inshellisense if available
    if command -v is &>/dev/null
      eval (is init fish)
    end
  '';

  # Nushell integration
  programs.nushell.extraEnv = lib.mkAfter ''
    # Initialize inshellisense if available
    if (which is | is-not-empty) {
      is init nu | save --force $"($nu.config-path)/inshellisense.nu"
    }
  '';

  programs.nushell.extraConfig = lib.mkAfter ''
    # Source inshellisense config if it exists
    if ($"($nu.config-path)/inshellisense.nu" | path exists) {
      source $"($nu.config-path)/inshellisense.nu"
    }
  '';

  # Create inshellisense config file
  xdg.configFile."inshellisense/rc.toml".text = ''
    # Use aliases in bash/zsh
    useAliases = true

    # Use NerdFont icons
    useNerdFont = true

    # Keybindings
    [bindings.acceptSuggestion]
    key = "tab"
    shift = false
    ctrl = false

    [bindings.nextSuggestion]
    key = "down"

    [bindings.previousSuggestion]
    key = "up"

    [bindings.dismissSuggestions]
    key = "escape"
  '';
}
