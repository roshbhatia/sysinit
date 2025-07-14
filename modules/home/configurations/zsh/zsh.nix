{
  config,
  lib,
  pkgs,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  logLib = shell.stripHeaders ./core/loglib.sh;
  paths = shell.stripHeaders ./core/paths.sh;
  wezterm = shell.stripHeaders ./core/wezterm.sh;
  completions = shell.stripHeaders ./core/completions.sh;
  kubectl = shell.stripHeaders ./core/kubectl.sh;
  env = shell.stripHeaders ./core/env.sh;
  extras = shell.stripHeaders ./core/extras.sh;
  prompt = shell.stripHeaders ./core/prompt.sh;
in
{
  programs.zsh = {
    enable = true;

    autocd = true;
    # We enable completion anyways, we don't want our cache to be invalidated.
    enableCompletion = false;
    historySubstringSearch.enable = false;
    # We need to install this manually due to fzf-tab needing to run first
    autosuggestion.enable = false;
    # We use fast-syntax-highlighting instead
    syntaxHighlighting.enable = false;

    history = {
      size = 50000;
      save = 50000;
      ignoreDups = true;
      ignoreSpace = true;
      extended = true;
      share = true;
    };

    dirHashes = {
      dl = "${config.home.homeDirectory}/Downloads";
      docs = "${config.home.homeDirectory}/Documents";
      dsk = "${config.home.homeDirectory}/Desktop";
      ghp = "${config.home.homeDirectory}/github/personal";
      ghpr = "${config.home.homeDirectory}/github/personal/roshbhatia";
      ghw = "${config.home.homeDirectory}/github/work";
      nvim = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim";
      sysinit = "${config.home.homeDirectory}/github/personal/roshbhatia/sysinit";
    };

    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      code = "code-insiders";
      c = "code-insiders";

      kubectl = "kubecolor";

      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'";

      tf = "terraform";
      y = "yazi";
      v = "nvim";
      g = "git";

      sudo = "sudo -E";

      diff = "diff --color";
      grep = "grep -s --color=auto";

      watch = "watch --color --no-title";
    };

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      XDG_CACHE_HOME = "${config.home.homeDirectory}/.cache";
      XDG_CONFIG_HOME = "${config.home.homeDirectory}/.config";
      XDG_DATA_HOME = "${config.home.homeDirectory}/.local/share";
      XDG_STATE_HOME = "${config.home.homeDirectory}/.local/state";

      XCA = "${config.home.homeDirectory}/.cache";
      XCO = "${config.home.homeDirectory}/.config";
      XDA = "${config.home.homeDirectory}/.local/share";
      XST = "${config.home.homeDirectory}/.local/state";

      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;

      ZSH_EVALCACHE_DIR = "${config.home.homeDirectory}/.local/share/zsh/evalcache";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#957e9d,italic";

      ZVM_LINE_INIT_MODE = "i";

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--bind='resize:refresh-preview'"
        "--color=bg+:-1,bg:-1,spinner:#f5c2e7,hl:#f38ba8"
        "--color=border:#6c7086,label:#cdd6f4"
        "--color=fg:#cdd6f4,header:#f38ba8,info:#89dceb,pointer:#f5c2e7"
        "--color=marker:#cba6f7,fg+:#cdd6f4,prompt:#89dceb,hl+:#f38ba8"
        "--cycle"
        "--height=30"
        "--highlight-line"
        "--ignore-case"
        "--info=inline"
        "--input-border=rounded"
        "--layout=reverse"
        "--list-border=rounded"
        "--no-scrollbar"
        "--pointer='>'"
        "--preview-border=rounded"
        "--prompt='>> '"
        "--scheme='history'"
        "--style='minimal'"
      ];

      EZA_COLORS = lib.concatStringsSep ";" [
        # directory color: #89b4fa (bright blue)
        "di=38;5;117"
        # symlink color: #fab387 (peach)
        "ln=38;5;216"
        # socket color: #cba6f7 (mauve)
        "so=38;5;183"
        # pipe color: #94e2d5 (teal)
        "pi=38;5;152"
        # executable color: #a6e3a1 (green)
        "ex=38;5;151"
        # block device color: #f9e2af (yellow) with background: #45475a
        "bd=38;5;223;48;5;238"
        # char device color: #f38ba8 (pink) with background: #45475a
        "cd=38;5;211;48;5;238"
        # setuid color: #f38ba8 (pink) with background: #585b70
        "su=38;5;211;48;5;240"
        # setgid color: #fab387 (peach) with background: #585b70
        "sg=38;5;216;48;5;240"
        # sticky other writable color: #a6e3a1 (green) with background: #45475a
        "tw=38;5;151;48;5;238"
        # other writable color: #94e2d5 (teal) with background: #45475a
        "ow=38;5;152;48;5;238"
      ];

      COLIMA_HOME = "${config.home.homeDirectory}/.config/colima";

      NVIM_LISTEN_ADDRESS = "${config.home.homeDirectory}/.cache/nvim";
    };

    plugins = [
      {
        name = "zsh-vi-mode";
        src = pkgs.fetchFromGitHub {
          owner = "jeffreytse";
          repo = "zsh-vi-mode";
          rev = "v0.11.0";
          sha256 = "sha256-xbchXJTFWeABTwq6h4KWLh+EvydDrDzcY9AQVK65RS8=";
        };
        file = "zsh-vi-mode.plugin.zsh";
      }
      {
        name = "evalcache";
        src = pkgs.fetchFromGitHub {
          owner = "mroth";
          repo = "evalcache";
          rev = "3153dcd77a2c93aa8fdf5d17cece7edb1aa3e040";
          sha256 = "GAjsTQJs9JdBEf9LGurme3zqXN//kVUM2YeBo0sCR2c=";
        };
        file = "evalcache.plugin.zsh";
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "v1.2.0";
          sha256 = "sha256-q26XVS/LcyZPRqDNwKKA9exgBByE0muyuNb0Bbar2lY=";
        };
        file = "fzf-tab.plugin.zsh";
      }
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "0e810e5afa27acbd074398eefbe28d13005dbc15";
          sha256 = "sha256-85aw9OM2pQPsWklXjuNOzp9El1MsNb+cIiZQVHUzBnk=";
        };
        file = "zsh-autosuggestions.plugin.zsh";
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma-continuum";
          repo = "fast-syntax-highlighting";
          rev = "cf318e06a9b7c9f2219d78f41b46fa6e06011fd9";
          sha256 = "sha256-RVX9ZSzjBW3LpFs2W86lKI6vtcvDWP6EPxzeTcRZua4=";
        };
        file = "fast-syntax-highlighting.plugin.zsh";
      }
    ];

    initContent = lib.mkMerge [
      (lib.mkBefore ''
        # modules/darwin/home/zsh/zsh.nix#initContent
        # THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
        # shellcheck disable=all
        [[ -n "$SYSINIT_DEBUG" ]] && zmodload zsh/zprof
        unset MAILCHECK
        stty stop undef
        setopt COMBINING_CHARS
        setopt PROMPT_SUBST
        PROMPT='%~%# '
        RPS1=""
      '')

      (lib.mkOrder 550 ''
        mkdir -p ${config.home.homeDirectory}/.config/zsh
        autoload bashcompinit && bashcompinit
        autoload -Uz compinit
        if [[ -n ${config.home.homeDirectory}/.config/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
          compinit -d "${config.home.homeDirectory}/.config/zsh/zcompdump/.zcompdump";
        else
          compinit -C -d "${config.home.homeDirectory}/.config/zsh/zcompdump/.zcompdump";
        fi

        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''\${(s.:.)LS_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*:complete:*' use-cache on
        zstyle ':completion:*' menu no

        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:cat:*' fzf-preview  'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:bat:*' fzf-preview  'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:nvim:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:vim:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:vi:*' fzf-preview 'fzf-preview "$realpath"'
        zstyle ':fzf-tab:complete:v:*' fzf-preview 'fzf-preview "$realpath"'

        zstyle ':fzf-tab:*' use-fzf-default-opts yes

      '')

      ''
        ${logLib}
        ${paths}
        ${wezterm}
        ${kubectl}
        ${env}
        ${extras}
        ${completions}
        ${prompt}
      ''

      (lib.mkAfter ''
        function zvm_vi_yank() {
          zvm_yank
          echo ''${CUTBUFFER} | pbcopy
          zvm_exit_visual_mode
        }

        function zvm_vi_delete() {
          zvm_replace_selection
          echo ''${CUTBUFFER} | pbcopy
          zvm_exit_visual_mode ''\${"1:-true"}
        }

        [[ -n "$SYSINIT_DEBUG" ]] && zprof
      '')
    ];
  };

  xdg.configFile = {
    "zsh/bin/dns-flush" = {
      source = ./bin/dns-flush;
      force = true;
    };

    "zsh/bin/fzf-preview" = {
      source = ./bin/fzf-preview;
      force = true;
    };

    "zsh/bin/git-ai-commit" = {
      source = ./bin/git-ai-commit;
      force = true;
    };

    "zsh/bin/gh-whoami" = {
      source = ./bin/gh-whoami;
      force = true;
    };
  };
}
