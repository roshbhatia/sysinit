if (which oh-my-posh | is-not-empty) {
  oh-my-posh init nu --config $"($env.XDG_CONFIG_HOME)/oh-my-posh/themes/sysinit.omp.json" | save --force $"($env.XDG_CACHE_HOME)/omp.nu"
  source $"($env.XDG_CACHE_HOME)/omp.nu"
}
