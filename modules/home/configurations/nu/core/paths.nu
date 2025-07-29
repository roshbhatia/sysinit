#!/jsr/bin/env nu
# THIS FILE WAS INSTALLED BY SYSINIT. MODIFICATIONS WILL BE OVERWRITTEN UPON UPDATE.
# shellcheck disable=all
# modules/darwin/home/nu/core/paths.nu (begin)
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
# modules/darwin/home/nu/core/paths.nu (end)

