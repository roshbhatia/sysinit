alias ..... = cd ../../../..
alias .... = cd ../../..
alias ... = cd ../..
alias .. = cd ..
alias ~ = cd ~
alias code = code-insiders
alias c = code-insiders
alias kubectl = kubecolor
alias l = eza --icons=always -1
alias la = eza --icons=always -1 -a
alias ll = eza --icons=always -1 -a
alias ls = eza
alias lt = eza --icons=always -1 -a -T --git-ignore --ignore-glob='.git'
alias tf = terraform
alias y = yazi
alias v = nvim
alias g = git
alias sudo = sudo -E
alias diff = diff --color
alias grep = grep -s --color=auto
alias watch = watch --color --no-title

$env.config.show_banner = false

# --- Macchina at shell startup (parity with zsh) ---
# Only run if not in NVIM and not in Wezterm pane 0
if ($env.WEZTERM_PANE? | is-empty) and ($env.NVIM? | is-empty) {
  let macchina_theme = ($env.MACCHINA_THEME? | default "rosh-color")
  macchina --theme $macchina_theme
}
