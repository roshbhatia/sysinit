{
  config,
  lib,
  pkgs,
  values,
  ...
}:
let
  shell = import ../../../lib/shell { inherit lib; };
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  ansiMappings =
    themes.ansiMappings.${values.theme.colorscheme}.${values.theme.variant}
      or themes.ansiMappings.catppuccin.macchiato;

  paths = shell.stripHeaders ./core/paths.sh;
  wezterm = shell.stripHeaders ./core/wezterm.sh;
  completions = shell.stripHeaders ./core/completions.sh;
  kubectl = shell.stripHeaders ./core/kubectl.sh;
  env = shell.stripHeaders ./core/env.sh;
  extras = shell.stripHeaders ./core/extras.sh;
  prompt = shell.stripHeaders ./core/prompt.sh;

  getThemeColors =
    colorscheme:
    if colorscheme == "catppuccin" then
      {
        autosuggest = palette.mauve or "#ca9ee6";
        fzf = {
          spinner = palette.pink or "#f4b8e4";
          hl = palette.red or "#e78284";
          border = palette.overlay0 or "#737994";
          label = palette.text or "#c6d0f5";
          fg = palette.text or "#c6d0f5";
          header = palette.red or "#e78284";
          info = palette.sky or "#99d1db";
          pointer = palette.pink or "#f4b8e4";
          marker = palette.mauve or "#ca9ee6";
          prompt = palette.sky or "#99d1db";
        };
      }
    else if colorscheme == "rose-pine" then
      {
        autosuggest = palette.iris or "#c4a7e7";
        fzf = {
          spinner = palette.love or "#eb6f92";
          hl = palette.love or "#eb6f92";
          border = palette.subtle or "#908caa";
          label = palette.text or "#e0def4";
          fg = palette.text or "#e0def4";
          header = palette.love or "#eb6f92";
          info = palette.foam or "#9ccfd8";
          pointer = palette.love or "#eb6f92";
          marker = palette.iris or "#c4a7e7";
          prompt = palette.foam or "#9ccfd8";
        };
      }
    else if colorscheme == "gruvbox" then
      {
        autosuggest = palette.purple or "#d3869b";
        fzf = {
          spinner = palette.orange or "#fe8019";
          hl = palette.red or "#fb4934";
          border = palette.gray or "#928374";
          label = palette.fg1 or "#ebdbb2";
          fg = palette.fg1 or "#ebdbb2";
          header = palette.red or "#fb4934";
          info = palette.blue or "#83a598";
          pointer = palette.orange or "#fe8019";
          marker = palette.purple or "#d3869b";
          prompt = palette.blue or "#83a598";
        };
      }
    else if colorscheme == "solarized" then
      {
        autosuggest = palette.violet or "#6c71c4";
        fzf = {
          spinner = palette.orange or "#cb4b16";
          hl = palette.red or "#dc322f";
          border = palette.base01 or "#586e75";
          label = palette.base0 or "#839496";
          fg = palette.base0 or "#839496";
          header = palette.red or "#dc322f";
          info = palette.blue or "#268bd2";
          pointer = palette.orange or "#cb4b16";
          marker = palette.violet or "#6c71c4";
          prompt = palette.blue or "#268bd2";
        };
      }
    else
      {
        autosuggest = "#c6a0f6";
        fzf = {
          spinner = "#f5bde6";
          hl = "#ed8796";
          border = "#6e738d";
          label = "#cad3f5";
          fg = "#cad3f5";
          header = "#ed8796";
          info = "#91d7e3";
          pointer = "#f5bde6";
          marker = "#c6a0f6";
          prompt = "#91d7e3";
        };
      };

  themeColors = getThemeColors values.theme.colorscheme values.theme.variant;
in
{
  programs.zsh = {
    enable = true;
    autocd = true;
    enableCompletion = false;
    historySubstringSearch.enable = false;
    autosuggestion.enable = false;
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
      ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE = "fg=${themeColors.autosuggest},italic";
      ZVM_LINE_INIT_MODE = "i";
      FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules";
      FZF_DEFAULT_OPTS = builtins.concatStringsSep " " [
        "--bind='resize:refresh-preview'"
        "--color=bg+:-1,bg:-1,spinner:${themeColors.fzf.spinner},hl:${themeColors.fzf.hl}"
        "--color=border:${themeColors.fzf.border},label:${themeColors.fzf.label}"
        "--color=fg:${themeColors.fzf.fg},header:${themeColors.fzf.header},info:${themeColors.fzf.info},pointer:${themeColors.fzf.pointer}"
        "--color=marker:${themeColors.fzf.marker},fg+:${themeColors.fzf.fg},prompt:${themeColors.fzf.prompt},hl+:${themeColors.fzf.hl}"
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
        "di=38;5;${ansiMappings.blue or "117"}"
        "ln=38;5;${ansiMappings.peach or ansiMappings.orange or "216"}"
        "so=38;5;${ansiMappings.mauve or ansiMappings.purple or "183"}"
        "pi=38;5;${ansiMappings.teal or ansiMappings.aqua or "152"}"
        "ex=38;5;${ansiMappings.green or "151"}"
        "bd=38;5;${ansiMappings.yellow or "223"};48;5;${ansiMappings.surface1 or ansiMappings.bg1 or "238"}"
        "cd=38;5;${ansiMappings.pink or ansiMappings.red or "211"};48;5;${
          ansiMappings.surface1 or ansiMappings.bg1 or "238"
        }"
        "su=38;5;${ansiMappings.pink or ansiMappings.red or "211"};48;5;${
          ansiMappings.surface2 or ansiMappings.bg2 or "240"
        }"
        "sg=38;5;${ansiMappings.peach or ansiMappings.orange or "216"};48;5;${
          ansiMappings.surface2 or ansiMappings.bg2 or "240"
        }"
        "tw=38;5;${ansiMappings.green or "151"};48;5;${ansiMappings.surface1 or ansiMappings.bg1 or "238"}"
        "ow=38;5;${ansiMappings.teal or ansiMappings.aqua or "152"};48;5;${
          ansiMappings.surface1 or ansiMappings.bg1 or "238"
        }"
      ];
      COLIMA_HOME = "${config.home.homeDirectory}/.config/colima";
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
        ${paths}
        ${wezterm}
        ${kubectl}
        ${env}
        ${extras}
        ${completions}
        ${prompt}
        if command -v carapace &>/dev/null; then
          eval "$(carapace _carapace)"
        fi
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
}
