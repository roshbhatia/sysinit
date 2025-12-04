# Wezterm shell integration for nushell
# Sets working directory via OSC 7
def __wezterm_osc7 [] {
  if (which wezterm | is-not-empty) {
    wezterm set-working-directory 2> /dev/null
  } else {
    printf "\033]7;file://%s%s\033\\" $"($env.HOSTNAME)" $env.PWD
  }
}

# Hook into nushell env-change to update working directory
$env.config.hooks.env_change.PWD = [
  { if (which wezterm | is-not-empty) {
    wezterm set-working-directory 2> /dev/null
  }}
]
