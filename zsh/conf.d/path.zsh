# Node.js
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# Python
export PATH="/usr/local/opt/cython/bin:$PATH"
export PATH="$PATH:/Users/$USER/.local/bin"

# Ruby
export PATH="$HOME/.rvm/bin:$PATH"

# Go
export GOENV_ROOT="$HOME/.goenv"
export PATH="$GOENV_ROOT/bin:$PATH"

export GOENV_SHELL=zsh
export GOENV_ROOT=/Users/$USER/.goenv
if [ -z ${GOENV_RC_FILE} ]; then
  GOENV_RC_FILE=${HOME}/.goenvrc
fi
if [ -e ${GOENV_RC_FILE} ]; then
  source ${GOENV_RC_FILE}
fi
if [ "${PATH#*$GOENV_ROOT/shims}" = "${PATH}" ]; then
  if [ "${GOENV_PATH_ORDER}" = "front" ] ; then
    export PATH="${GOENV_ROOT}/shims:${PATH}"
  else
    export PATH="${PATH}:${GOENV_ROOT}/shims"
  fi
fi
source "/Users/${USER}/.goenv/libexec/../completions/goenv.zsh"
(command goenv rehash 2>/dev/null &)
goenv() {
  local command
  command="$1"
  if [ "$#" -gt 0 ]; then
    shift
  fi

  case "$command" in
  rehash|shell)
    eval "$(goenv "sh-$command" "$@")";;
  *)
    command goenv "$command" "$@";;
  esac
}
(goenv rehash --only-manage-paths &)

export GOPATH="$(go env GOPATH 2>/dev/null || echo "$HOME/go")"
export GOROOT="$(go env GOROOT 2>/dev/null || echo "$(brew --prefix golang)/libexec")"
export PATH="$GOROOT/bin:$PATH"
export PATH="$GOPATH/bin:$PATH"

# Kubernetes
export PATH="$HOME/.krew/bin:$PATH"
