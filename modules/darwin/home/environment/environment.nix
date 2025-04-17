# Home environment configuration
{ config, lib, pkgs, ... }:

{
  # Set environment variables
  home.sessionVariables = {    
    # XDG Base Directory
    XDG_CACHE_HOME = "$HOME/.cache";
    XDG_CONFIG_HOME = "$HOME/.config";
    XDG_DATA_HOME = "$HOME/.local/share";
    XDG_STATE_HOME = "$HOME/.local/state";
    
    # Ensure local binaries are in PATH
    PATH = "/usr/bin:/usr/sbin:/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/bin:$PATH";
    
    # Locale settings
    LANG = "en_US.UTF-8";
    LC_ALL = "en_US.UTF-8";
  };
  
  # Set shell options
  home.sessionPath = [
    "$HOME/.local/bin"
    "$HOME/bin"
  ];
}
