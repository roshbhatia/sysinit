{
  config,
  lib,
  values,
  pkgs,
  ...
}:
let
  # Aliases as Nushell code
  aliases = lib.concatStringsSep "\n" [
    "alias ..... = cd ../../../.."
    "alias .... = cd ../../.."
    "alias ... = cd ../.."
    "alias .. = cd .."
    "alias ~ = cd ~"
    "alias code = code-insiders"
    "alias c = code-insiders"
    "alias kubectl = kubecolor"
    "alias l = eza --icons=always -1"
    "alias la = eza --icons=always -1 -a"
    "alias ll = eza --icons=always -1 -a"
    "alias ls = eza"
    "alias lt = eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'"
    "alias tf = terraform"
    "alias y = yazi"
    "alias v = nvim"
    "alias g = git"
    "alias sudo = sudo -E"
    "alias diff = diff --color"
    "alias grep = grep -s --color=auto"
    "alias watch = watch --color --no-title"
  ];

  # Env vars as Nushell code, using Nix options
  env = lib.concatStringsSep "\n" [
    "$env.LANG = \"en_US.UTF-8\""
    "$env.LC_ALL = \"en_US.UTF-8\""
    "$env.XDG_CACHE_HOME = \"${config.home.homeDirectory}/.cache\""
    "$env.XDG_CONFIG_HOME = \"${config.home.homeDirectory}/.config\""
    "$env.XDG_DATA_HOME = \"${config.home.homeDirectory}/.local/share\""
    "$env.XDG_STATE_HOME = \"${config.home.homeDirectory}/.local/state\""
    "$env.SUDO_EDITOR = \"nvim\""
    "$env.VISUAL = \"nvim\""
    "$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = \"1\""
    "$env.FZF_DEFAULT_COMMAND = \"fd --type f --hidden --follow --exclude .git --exclude node_modules\""
    "$env.COLIMA_HOME = \"${config.home.homeDirectory}/.config/colima\""
    "$env.PATH = ($env.PATH | split row (char esep) | prepend '/usr/local/bin' | uniq | str join (char esep))"
    "$env.MANPAGER = \"nvim +Man!\""
  ];

  # Prompt and extras (inline or as needed)
  prompt = ''
    # Prompt setup
    source ~/.cache/omp.nu
  '';

  extras = ''
    try { source ~/.local/share/atuin/init.nu } catch { }
    try { source ~/.nix-profile/share/zoxide/init.nu } catch { }
    try { source ~/.nix-profile/share/direnv/direnv.nu } catch { }
    if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
      let macchina_theme = ($env.MACCHINA_THEME? | default "rosh")
      macchina --theme $macchina_theme
    }
    oh-my-posh init nu --config ~/.config/oh-my-posh/themes/sysinit.omp.json | save --raw ~/.cache/omp.nu
    source ~/.cache/omp.nu
  '';

  # Main Nushell config
  configText = lib.concatStringsSep "\n" [
    aliases
    env
    prompt
    extras
    ''
      let carapace_completer = {|spans| carapace $spans.0 nushell ...$spans | from json }
      $env.config.show_banner = false
      $env.config.edit_mode = "vi"
      $env.config.completions = {
        case_sensitive: false
        quick: true
        partial: true
        algorithm: "fuzzy"
        external: {
          enable: true
          max_results: 100
          completer: $carapace_completer
        }
      }
    ''
  ];
in
{
  programs.nushell = {
    enable = true;
    configFile.text = configText;
    plugins = with pkgs.nushellPlugins; [
      hcl
      query
      semver
      highlight
    ];
  };
}
