#!/usr/bin/env bash

if [ -z "${XDG_CONFIG_HOME+x}" ]; then
	export XDG_CONFIG_HOME="$HOME/.config"
fi

if [ -z "${XDG_DATA_HOME+x}" ]; then
	export XDG_DATA_HOME="$HOME/.local/share"
fi

export PATH="/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.npm-global/bin/yarn:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.yarn/global/node_modules/.bin:$PATH"
export PATH="$XDG_CONFIG_HOME/yarn/global/node_modules/.bin:$PATH"
export PATH="/usr/local/opt/cython/bin:$PATH"
export PATH="$HOME/.uv/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="$HOME/.krew/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/zsh/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
export PATH="$XDG_DATA_HOME/.npm-packages/bin:$PATH"

log_info() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') INFO $1"
}

log_debug() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') DEBUG $1"
}

log_error() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') ERROR $1"
}

log_success() {
	echo "$(date '+%Y-%m-%d %H:%M:%S') SUCCESS $1"
}

log_command() {
	local cmd="$1"
	local description="$2"
	log_info "Running: $description"

	local output
	if output=$(eval "$cmd" 2>&1); then
		log_success "$description completed"
		[ -n "$output" ] && echo "$output"
		return 0
	else
		local exit_code=$?
		log_error "$description failed with exit code $exit_code"
		[ -n "$output" ] && echo "$output"
		return $exit_code
	fi
}

check_executable() {
	local executable="$1"
	if ! command -v "$executable" &>/dev/null; then
		log_error "$executable not found in PATH"
		return 1
	fi
	log_debug "Found $executable at $(command -v "$executable")"
	return 0
}
