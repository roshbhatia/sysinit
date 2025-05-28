{
  lib,
  pkgs,
  homeDirectory,
  ...
}:

let
  stripHeaders =
    file:
    let
      content = builtins.readFile file;
      lines = lib.splitString "\n" content;
      isHeaderLine =
        line:
        lib.hasPrefix "#!/usr/bin/env zsh" line
        || lib.hasPrefix "# THIS FILE WAS INSTALLED BY SYSINIT" line
        || lib.hasPrefix "# shellcheck disable" line;
      nonHeaderLines = builtins.filter (line: !(isHeaderLine line)) lines;
    in
    lib.concatStringsSep "\n" nonHeaderLines;

  logLib = stripHeaders ./core/loglib.sh;
  paths = stripHeaders ./core/paths.sh;
  wezterm = stripHeaders ./core/wezterm.sh;
  completions = stripHeaders ./core/completions.sh;
  kubectl = stripHeaders ./core/kubectl.sh;
  env = stripHeaders ./core/env.sh;
  extras = stripHeaders ./core/extras.sh;
  prompt = stripHeaders ./core/prompt.sh;
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
      dsk = "${homeDirectory}/Desktop";
      docs = "${homeDirectory}/Documents";
      dl = "${homeDirectory}/Downloads";
      ghp = "${homeDirectory}/github/personal";
      ghpr = "${homeDirectory}/github/personal/roshbhatia";
      ghw = "${homeDirectory}/github/work";
    };

    shellAliases = {
      "....." = "cd ../../../..";
      "...." = "cd ../../..";
      "..." = "cd ../..";
      ".." = "cd ..";
      "~" = "cd ~";

      code = "code-insiders";
      kubectl = "kubecolor";

      l = "eza --icons=always -1";
      la = "eza --icons=always -1 -a";
      ll = "eza --icons=always -1 -a";
      ls = "eza";
      lt = "eza --icons=always -1 -a -T";

      tf = "terraform";
      y = "yazi";
      v = "nvim";

      sudo = "sudo -E";

      diff = "diff --color";
      grep = "grep -s --color=auto";
    };

    sessionVariables = {
      LANG = "en_US.UTF-8";
      LC_ALL = "en_US.UTF-8";

      # Clobbers the home manager defined ones? Maybe?
      XDG_CACHE_HOME = "${homeDirectory}/.cache";
      XDG_CONFIG_HOME = "${homeDirectory}/.config";
      XDG_DATA_HOME = "${homeDirectory}/.local/share";
      XDG_STATE_HOME = "${homeDirectory}/.local/state";

      XCA = "${homeDirectory}/.cache";
      XCO = "${homeDirectory}/.config";
      XDA = "${homeDirectory}/.local/share";
      XST = "${homeDirectory}/.local/state";

      GIT_DISCOVERY_ACROSS_FILESYSTEM = 1;

      ZSH_EVALCACHE_DIR = "${homeDirectory}/.local/share/zsh/evalcache";

      ZSH_AUTOSUGGEST_USE_ASYNC = 1;
      ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE = 20;
      ZSH_AUTOSUGGEST_MANUAL_REBIND = 1;
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=#808080,bold,underline";

      ZVM_LINE_INIT_MODE = "i";

      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--preview-window=right:60%:wrap:border-rounded"
        "--height=80%"
        "--layout=reverse"
        "--border=rounded"
        "--margin=1"
        "--padding=1"
        "--info=inline-right"
        "--prompt='❯ '"
        "--pointer='▶'"
        "--marker='✓'"
        "--scrollbar='█'"
        "--color=bg+:#2a273f,bg:#191724,spinner:#ebbcba,hl:#eb6f92"
        "--color=fg:#e0def4,header:#eb6f92,info:#9ccfd8,pointer:#ebbcba"
        "--color=marker:#c4a7e7,fg+:#e0def4,prompt:#9ccfd8,hl+:#eb6f92"
        "--color=selected-bg:#31748f"
        "--color=border:#2a273f,label:#e0def4"
        "--bind='resize:refresh-preview'"
      ];

      SUDO_EDITOR = "nvim";
      VISUAL = "nvim";
      PAGER = "bat --pager=always --color=always";

      EZA_COLORS = "di=38;5;109:ln=38;5;108:so=38;5;110:pi=38;5;109:ex=38;5;142:bd=38;5;109;48;5;236:cd=38;5;109;48;5;236:su=38;5;109;48;5;236:sg=38;5;109;48;5;236:tw=38;5;109;48;5;236:ow=38;5;109;48;5;236";
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
        mkdir -p ~/.config/zsh
        autoload -Uz compinit
        if [[ -n ~/.config/zsh/zcompdump/.zcompdump(#qN.mh+24) ]]; then
          compinit -d "~/.config/zsh/zcompdump/.zcompdump";
        else
          compinit -C -d "~/.config/zsh/zcompdump/.zcompdump";
        fi

        zstyle ':completion:*:git-checkout:*' sort false
        zstyle ':completion:*:descriptions' format '[%d]'
        zstyle ':completion:*' list-colors ''\${(s.:.)EZA_COLORS}
        zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
        zstyle ':completion:*' menu no
        zstyle ':completion:*:complete:*' use-cache on
        zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --icons=always -1 -a ''\$realpath'
        zstyle ':fzf-tab:complete:cat:*' fzf-preview 'bat --color=always ''\$realpath'
        zstyle ':fzf-tab:complete:bat:*' fzf-preview 'bat --color=always ''\$realpath'
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
        [[ -n "$SYSINIT_DEBUG" ]] && zprof
      '')
    ];
  };

  xdg.configFile = {
    "zsh/bin/colima-recreate" = {
      source = ./bin/colima-recreate;
      force = true;
    };

    "zsh/bin/dns-flush" = {
      source = ./bin/dns-flush;
      force = true;
    };

    "zsh/bin/gh-whoami" = {
      source = ./bin/gh-whoami;
      force = true;
    };

    "zsh/bin/ghcs-commitmessage" = {
      source = ./bin/ghcs-commitmessage;
      force = true;
    };

    "zsh/bin/kubectl-crdbrowse" = {
      source = ./bin/kubectl-crdbrowse;
      force = true;
    };

    "zsh/bin/kubectl-kdesc" = {
      source = ./bin/kubectl-kdesc;
      force = true;
    };

    "zsh/bin/kubectl-kexec" = {
      source = ./bin/kubectl-kexec;
      force = true;
    };

    "zsh/bin/kubectl-kproxy" = {
      source = ./bin/kubectl-kproxy;
      force = true;
    };
  };
}

