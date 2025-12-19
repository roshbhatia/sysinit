def setup_completions [] {
  atuin init nu
  docker completion nushell
  task --completion nu
  kubecolor completion nushell
  uv generate-shell-completion nu
}

setup_completions
