#!/usr/bin/env bash
set -euo pipefail

# Runs nvim on a remote host and attaches this terminal as its UI, so the
# editor, its LSPs and its plugins all run next to the files while only the
# UI protocol crosses the network.

usage() {
  cat >&2 << 'EOF'
Usage: rnvim [user@]host[:dir]

Starts (or reattaches to) an nvim server on the host, rooted at dir, and
draws its UI in this terminal. dir defaults to the remote home directory.

  :detach   leave the remote session running, close this UI
  :qa       end the remote session

Reconnecting after a dropped link is the same command again.
EOF
}

# The session key has to survive both ends, so it is derived from the target
# rather than stored anywhere.
session_key() {
  local host="$1"
  local dir="$2"
  printf '%s\n' "${host} ${dir}" | sha256sum | cut -c1-10
}

start_remote() {
  local ctl="$1"
  local host="$2"
  local dir="$3"
  local sock="$4"

  ssh -S "${ctl}" "${host}" bash -s -- "${dir}" "${sock}" << 'REMOTE'
set -euo pipefail

# Deliberately not a login shell: NixOS sources /etc/bash_logout on exit, which
# reads an unset variable and so trips this script's own `set -u`. The nix
# profile directories go on PATH by hand instead.
PATH="$HOME/.nix-profile/bin:/etc/profiles/per-user/$(id -un)/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:$PATH"

dir="${1/#\~/$HOME}"
sock="$2"

if [ ! -d "${dir}" ]; then
  echo "ERROR: ${dir} is not a directory on this host" >&2
  exit 1
fi

# An existing server answers, so reattach to it instead of starting a second.
if [ -S "${sock}" ] && nvim --server "${sock}" --remote-expr 1 > /dev/null 2>&1; then
  exit 0
fi

mkdir -p "$(dirname "${sock}")"
rm -f "${sock}"

cd "${dir}"
# nohup, not setsid: setsid is missing on darwin hosts. SSH_CONNECTION stays in
# the environment, which is what makes the remote config pick OSC 52 clipboard.
nohup nvim --headless --listen "${sock}" < /dev/null > /dev/null 2>&1 &

for _ in $(seq 1 100); do
  if [ -S "${sock}" ]; then
    exit 0
  fi
  sleep 0.1
done

echo "ERROR: nvim never created ${sock}" >&2
exit 1
REMOTE
}

# The EXIT trap fires after main has returned, so what it tears down cannot be
# local to main.
ctl=""
lsock=""
host=""

cleanup() {
  if [ -n "${ctl}" ]; then
    ssh -S "${ctl}" -O exit "${host}" > /dev/null 2>&1 || true
  fi
  if [ -n "${lsock}" ]; then
    rm -f "${lsock}" "${ctl}"
  fi
}

main() {
  local target="${1:-}"

  case "${target}" in
    -h | --help)
      usage
      exit 0
      ;;
    "" | -*)
      usage
      exit 1
      ;;
  esac

  host="${target%%:*}"
  local dir="."
  if [[ ${target} == *:* ]]; then
    dir="${target#*:}"
  fi

  # /tmp rather than TMPDIR: darwin's per-user TMPDIR is long enough to push a
  # socket path past the 104 byte sun_path limit.
  local run_dir
  run_dir="/tmp/rnvim-$(id -u)"
  mkdir -p "${run_dir}"
  chmod 700 "${run_dir}"

  local key
  key="$(session_key "${host}" "${dir}")"
  # Both paths carry the pid, so a second UI onto the same session gets its own
  # tunnel instead of colliding with the first.
  ctl="${run_dir}/${key}.$$.ctl"
  lsock="${run_dir}/${key}.$$.sock"
  trap cleanup EXIT

  # One multiplexed connection carries the bootstrap and the forward, so
  # 1Password only asks to authorise the key once.
  ssh -f -N -M -S "${ctl}" -o ControlPersist=no "${host}"

  local remote_home
  remote_home="$(ssh -S "${ctl}" "${host}" 'printf %s "$HOME"')"
  local rsock="${remote_home}/.cache/rnvim/${key}.sock"

  start_remote "${ctl}" "${host}" "${dir}" "${rsock}"

  ssh -S "${ctl}" -O forward -L "${lsock}:${rsock}" "${host}" > /dev/null

  nvim --server "${lsock}" --remote-ui
}

main "$@"
