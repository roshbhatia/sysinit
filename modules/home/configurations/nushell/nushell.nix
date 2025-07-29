{
  config,
  lib,
  pkgs,
  values,
  ...
}:

let
  themes = import ../../../lib/themes { inherit lib; };
  palette = themes.getThemePalette values.theme.colorscheme values.theme.variant;
  ansiMappings =
    themes.ansiMappings.${values.theme.colorscheme}.${values.theme.variant}
      or themes.ansiMappings.catppuccin.macchiato;

  getFzfColors = colorscheme:
    if colorscheme == "catppuccin" then
      "--color=bg+:-1,bg:-1,spinner:${palette.pink or "#f4b8e4"},hl:${palette.red or "#e78284"} --color=border:${palette.overlay0 or "#737994"},label:${palette.text or "#c6d0f5"} --color=fg:${palette.text or "#c6d0f5"},header:${palette.red or "#e78284"},info:${palette.sky or "#99d1db"},pointer:${palette.pink or "#f4b8e4"} --color=marker:${palette.mauve or "#ca9ee6"},fg+:${palette.text or "#c6d0f5"},prompt:${palette.sky or "#99d1db"},hl+:${palette.red or "#e78284"}"
    else if colorscheme == "rose-pine" then
      "--color=bg+:-1,bg:-1,spinner:${palette.love or "#eb6f92"},hl:${palette.love or "#eb6f92"} --color=border:${palette.subtle or "#908caa"},label:${palette.text or "#e0def4"} --color=fg:${palette.text or "#e0def4"},header:${palette.love or "#eb6f92"},info:${palette.foam or "#9ccfd8"},pointer:${palette.love or "#eb6f92"} --color=marker:${palette.iris or "#c4a7e7"},fg+:${palette.text or "#e0def4"},prompt:${palette.foam or "#9ccfd8"},hl+:${palette.love or "#eb6f92"}"
    else if colorscheme == "gruvbox" then
      "--color=bg+:-1,bg:-1,spinner:${palette.orange or "#fe8019"},hl:${palette.red or "#fb4934"} --color=border:${palette.gray or "#928374"},label:${palette.fg1 or "#ebdbb2"} --color=fg:${palette.fg1 or "#ebdbb2"},header:${palette.red or "#fb4934"},info:${palette.blue or "#83a598"},pointer:${palette.orange or "#fe8019"} --color=marker:${palette.purple or "#d3869b"},fg+:${palette.fg1 or "#ebdbb2"},prompt:${palette.blue or "#83a598"},hl+:${palette.red or "#fb4934"}"
    else if colorscheme == "solarized" then
      "--color=bg+:-1,bg:-1,spinner:${palette.orange or "#cb4b16"},hl:${palette.red or "#dc322f"} --color=border:${palette.base01 or "#586e75"},label:${palette.base0 or "#839496"} --color=fg:${palette.base0 or "#839496"},header:${palette.red or "#dc322f"},info:${palette.blue or "#268bd2"},pointer:${palette.orange or "#cb4b16"} --color=marker:${palette.violet or "#6c71c4"},fg+:${palette.base0 or "#839496"},prompt:${palette.blue or "#268bd2"},hl+:${palette.red or "#dc322f"}"
    else
      "--color=bg+:-1,bg:-1,spinner:#f5bde6,hl:#ed8796 --color=border:#6e738d,label:#cad3f5 --color=fg:#cad3f5,header:#ed8796,info:#91d7e3,pointer:#f5bde6 --color=marker:#c6a0f6,fg+:#cad3f5,prompt:#91d7e3,hl+:#ed8796";

  fzfColors = getFzfColors values.theme.colorscheme;

  envNu = ''
    def path_add [dir: string] {
      if ($dir | path exists) {
        $env.PATH = ($env.PATH | split row (char esep) | prepend $dir | uniq | str join (char esep))
      }
    }

    let paths = [
      "/opt/homebrew/bin"
      "/opt/homebrew/opt/libgit2@1.8/bin"
      "/opt/homebrew/sbin"
      "/usr/bin"
      "/usr/local/opt/cython/bin"
      "/usr/sbin"
      $"($env.HOME)/.cargo/bin"
      $"($env.HOME)/.krew/bin"
      $"($env.HOME)/.local/bin"
      $"($env.HOME)/.npm-global/bin"
      $"($env.HOME)/.npm-global/bin/yarn"
      $"($env.HOME)/.rvm/bin"
      $"($env.HOME)/.uv/bin"
      $"($env.HOME)/.yarn/bin"
      $"($env.HOME)/.yarn/global/node_modules/.bin"
      $"($env.HOME)/bin"
      $"($env.HOME)/go/bin"
      $"($env.XDG_CONFIG_HOME)/.cargo/bin"
      $"($env.XDG_CONFIG_HOME)/yarn/global/node_modules/.bin"
      $"($env.XDG_CONFIG_HOME)/zsh/bin"
      $"($env.XDG_DATA_HOME)/.npm-packages/bin"
    ]

    for path in $paths {
      path_add $path
    }

    $env.LANG = "en_US.UTF-8"
    $env.LC_ALL = "en_US.UTF-8"
    $env.SUDO_EDITOR = "nvim"
    $env.VISUAL = "nvim"
    $env.EDITOR = "nvim"
    $env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
    $env.COLIMA_HOME = $"($env.XDG_CONFIG_HOME)/colima"

    $env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
    $env.FZF_DEFAULT_OPTS = [
      "--bind=resize:refresh-preview"
      "${fzfColors}"
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
      "--scheme=history"
      "--style=minimal"
    ] | str join " "

    $env.EZA_COLORS = [
      $"di=38;5;(${ansiMappings.blue or "117"})"
      $"ln=38;5;(${ansiMappings.peach or ansiMappings.orange or "216"})"
      $"so=38;5;(${ansiMappings.mauve or ansiMappings.purple or "183"})"
      $"pi=38;5;(${ansiMappings.teal or ansiMappings.aqua or "152"})"
      $"ex=38;5;(${ansiMappings.green or "151"})"
      $"bd=38;5;(${ansiMappings.yellow or "223"});48;5;(${ansiMappings.surface1 or ansiMappings.bg1 or "238"})"
      $"cd=38;5;(${ansiMappings.pink or ansiMappings.red or "211"});48;5;(${ansiMappings.surface1 or ansiMappings.bg1 or "238"})"
      $"su=38;5;(${ansiMappings.pink or ansiMappings.red or "211"});48;5;(${ansiMappings.surface2 or ansiMappings.bg2 or "240"})"
      $"sg=38;5;(${ansiMappings.peach or ansiMappings.orange or "216"});48;5;(${ansiMappings.surface2 or ansiMappings.bg2 or "240"})"
      $"tw=38;5;(${ansiMappings.green or "151"});48;5;(${ansiMappings.surface1 or ansiMappings.bg1 or "238"})"
      $"ow=38;5;(${ansiMappings.teal or ansiMappings.aqua or "152"});48;5;(${ansiMappings.surface1 or ansiMappings.bg1 or "238"})"
    ] | str join ";"
  '';

  aliasesNu = ''
    alias ".." = cd ..
    alias "..." = cd ../..
    alias "...." = cd ../../..
    alias "....." = cd ../../../..
    alias "~" = cd ~

    alias l = eza --icons=always -1
    alias la = eza --icons=always -1 -a
    alias ll = eza --icons=always -1 -a
    alias ls = eza
    alias lt = eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'

    alias code = code-insiders
    alias c = code-insiders
    alias kubectl = kubecolor
    alias tf = terraform
    alias y = yazi
    alias v = nvim
    alias g = git
    alias diff = diff --color
    alias grep = grep -s --color=auto
    alias watch = watch --color --no-title

    alias cat = bat
    alias find = fd
  '';

  shortcutsNu = ''
    def --env dl [] { cd $"($env.HOME)/Downloads" }
    def --env docs [] { cd $"($env.HOME)/Documents" }
    def --env dsk [] { cd $"($env.HOME)/Desktop" }
    def --env ghp [] { cd $"($env.HOME)/github/personal" }
    def --env ghpr [] { cd $"($env.HOME)/github/personal/roshbhatia" }
    def --env ghw [] { cd $"($env.HOME)/github/work" }
    def --env nvim [] { cd $"($env.HOME)/github/personal/roshbhatia/sysinit/modules/home/configurations/neovim" }
    def --env sysinit [] { cd $"($env.HOME)/github/personal/roshbhatia/sysinit" }
  '';

  integrationsNu = ''
    try { source ~/.local/share/atuin/init.nu } catch { print "atuin not available" }
    try { source ~/.nix-profile/share/zoxide/init.nu } catch { print "zoxide not available" }
    try { source ~/.nix-profile/share/direnv/direnv.nu } catch { print "direnv not available" }

    if (which carapace | is-not-empty) {
      let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
      $env.config.completions.external = {
        enable: true
        max_results: 100
        completer: $carapace_completer
      }
    }

    if (which oh-my-posh | is-not-empty) {
      oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --force ~/.cache/omp.nu
      source ~/.cache/omp.nu
    }

    if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
      if (which macchina | is-not-empty) {
        let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
        macchina --theme $macchina_theme
      }
    }
  '';

  configNu = ''
    $env.config = {
      show_banner: false
      edit_mode: "vi"
      completions: {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
          enable: false  # Will be enabled in integrations if carapace is available
          max_results: 100
        }
      }
      cursor_shape: {
        vi_insert: underscore
        vi_normal: block
      }
      history: {
        max_size: 50000
        sync_on_enter: true
        file_format: "plaintext"
        isolation: false
      }
      keybindings: [
        {
          name: completion_menu
          modifier: none
          keycode: tab
          mode: [emacs vi_normal vi_insert]
          event: {
            until: [
              { send: menu name: completion_menu }
              { send: menunext }
              { edit: complete }
            ]
          }
        }
      ]
    }

    source ~/.config/nushell/aliases.nu
    source ~/.config/nushell/shortcuts.nu
    source ~/.config/nushell/integrations.nu
  '';

in
{
  programs.nushell = {
    enable = true;
    configFile.text = configNu;
    envFile.text = envNu;
  };

  home.file = {
    ".config/nushell/aliases.nu".text = aliasesNu;
    ".config/nushell/shortcuts.nu".text = shortcutsNu;
    ".config/nushell/integrations.nu".text = integrationsNu;
  };
}
