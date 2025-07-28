# Nushell Environment Variables (mirrors zsh/core/env.sh)
$env.LANG = "en_US.UTF-8"
$env.LC_ALL = "en_US.UTF-8"
$env.XDG_CACHE_HOME = ($nu.home-path | append ".cache" | path join)
$env.XDG_CONFIG_HOME = ($nu.home-path | append ".config" | path join)
$env.XDG_DATA_HOME = ($nu.home-path | append ".local/share" | path join)
$env.XDG_STATE_HOME = ($nu.home-path | append ".local/state" | path join)
$env.SUDO_EDITOR = "nvim"
$env.VISUAL = "nvim"
$env.GIT_DISCOVERY_ACROSS_FILESYSTEM = "1"
$env.FZF_DEFAULT_COMMAND = "fd --type f --hidden --follow --exclude .git --exclude node_modules"
$env.FZF_DEFAULT_OPTS = "--bind='resize:refresh-preview' ..."
$env.EZA_COLORS = "di=38;5;117;..."
$env.COLIMA_HOME = ($nu.home-path | append ".config/colima" | path join)
$env.PATH = ($env.PATH | split row (char esep) | prepend "/usr/local/bin" | uniq | str join (char esep))
$env.MANPAGER = "nvim +Man!"
