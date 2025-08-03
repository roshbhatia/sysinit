# Sysinit Values Configuration
# 
# This file defines the core configuration for your system.
# It's validated against a comprehensive type system to ensure correctness
# and provides autocomplete support in compatible editors.
#
# Theme Configuration Guide:
# ========================
# 
# Available colorschemes and their supported variants:
# 
# catppuccin:
#   - macchiato (recommended)
# 
# rose-pine:
#   - moon
# 
# gruvbox:
#   - dark
# 
# solarized:
#   - dark
# 
# nord:
#   - dark
# 
# kanagawa:
#   - wave
#   - dragon
#
# Transparency Configuration:
# ==========================
# 
# enable: Boolean to turn transparency on/off
# opacity: Float between 0.0 (invisible) and 1.0 (opaque)
# blur: Integer for background blur amount (0-200)
#
# Transparency Presets:
# - "none": No transparency
# - "light": Subtle transparency (opacity: 0.95)
# - "medium": Balanced transparency (opacity: 0.85) 
# - "heavy": Strong transparency (opacity: 0.70)

{
  # User Configuration
  # ==================
  user = {
    username = "rshnbhatia";    # System username
    hostname = "lv426";         # System hostname  
  };

  # Git Configuration
  # =================
  git = {
    userName = "Roshan Bhatia";           # Full name for git commits
    userEmail = "rshnbhatia@gmail.com";   # Email for git commits
    githubUser = "roshbhatia";            # GitHub username
    credentialUsername = "roshbhatia";    # Git credential helper username
  };

  # Homebrew Package Configuration
  # ==============================
  homebrew = {
    additionalPackages = {
      # Additional brew taps to install
      taps = [ 
        "hashicorp/tap" 
      ];
      
      # Additional CLI tools and services
      brews = [
        "blueutil"              # Bluetooth CLI utility
        "hashicorp/tap/packer"  # HashiCorp Packer
        "tailscale"             # Tailscale VPN
        "qemu"                  # QEMU virtualization
      ];
      
      # GUI applications
      casks = [
        "betterdiscord-installer"  # Discord customization
        "calibre"                  # E-book management
        "discord"                  # Discord chat
        "notion"                   # Note-taking and productivity
        "steam"                    # Gaming platform
        "supercollider"           # Audio synthesis platform
        "vnc-viewer"              # VNC remote desktop viewer
      ];
    };
  };

  # Yarn Package Configuration
  # ==========================
  yarn = {
    additionalPackages = [
      "@anthropic-ai/claude-code"  # Claude Code CLI
      "@dice-roller/cli"           # Dice rolling CLI tool
    ];
  };

  # Theme Configuration
  # ===================
  theme = {
    colorscheme = "catppuccin";  # Available: catppuccin, rose-pine, gruvbox, solarized, nord, kanagawa
    variant = "macchiato";       # For catppuccin: macchiato | For kanagawa: wave, dragon | Others: dark
    
    transparency = {
      enable = true;   # Enable transparency effects
      opacity = 0.85;  # Opacity level (0.0 - 1.0)
      blur = 80;       # Background blur amount (0-200)
    };
    
    # Optional: Apply transparency presets
    presets = [];  # Available: "none", "light", "medium", "heavy"
    
    # Optional: Custom color overrides
    overrides = {};  # Example: { accent = "#ff0000"; background = "#000000"; }
  };

  # Wezterm Configuration
  # =====================
  wezterm = {
    # Optional: Override transparency when Neovim is detected
    nvim_transparency_override = null;
    # Example:
    # nvim_transparency_override = {
    #   enable = true;
    #   opacity = 0.95;
    #   blur = 40;
    # };
  };

  # Additional Package Configurations
  # =================================
  # Uncomment and configure as needed:

  # cargo = {
  #   additionalPackages = [
  #     "ripgrep"
  #     "fd-find" 
  #     "bat"
  #   ];
  # };

  # nix = {
  #   packages = [
  #     "jq"
  #     "fd"
  #     "tree"
  #   ];
  # };

  # krew = {
  #   additionalPackages = [
  #     "ctx"
  #     "ns"
  #     "stern"
  #   ];
  # };
}