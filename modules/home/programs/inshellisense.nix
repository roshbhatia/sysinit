{ pkgs, lib, ... }:

{
  home.packages = [ pkgs.inshellisense ];

  # Nushell integration only
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
