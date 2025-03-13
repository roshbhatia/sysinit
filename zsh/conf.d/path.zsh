# Node.js
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Python
export PATH="/usr/local/opt/cython/bin:$PATH"
export PATH="$PATH:/Users/$USER/.local/bin"

# Ruby
export PATH="$HOME/.rvm/bin:$PATH"

# Rust
. "$HOME/.cargo/env"
export PATH="$HOME/.cargo/bin:$PATH"

# Go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
eval "$(goenv init -)" 2>/dev/null
export GOPATH="$(go env GOPATH 2>/dev/null || echo "$HOME/go")"
export GOROOT="$(go env GOROOT 2>/dev/null || echo "$(brew --prefix golang)/libexec")"
export PATH="$GOROOT/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"

# Kubernetes
export PATH="$HOME/.krew/bin:$PATH"
