#!/usr/bin/env bash
set -euo pipefail

system_profile=${1:-/nix/var/nix/profiles/system}
current_system=${2:-/run/current-system}
nix_env=${3:-/nix/var/nix/profiles/default/bin/nix-env}
readlink_command=${4:-/usr/bin/readlink}
sleep_command=${5:-/bin/sleep}
attempts=${6:-60}
interval=${7:-1}

if [[ ${system_profile} != /* || ${system_profile##*/} != system ]]; then
  printf 'ERROR: system profile must be an absolute path named system: %s\n' "${system_profile}" >&2
  exit 2
fi

if [[ ${current_system} != /* ]]; then
  printf 'ERROR: current system must be an absolute path: %s\n' "${current_system}" >&2
  exit 2
fi

for command_path in "${nix_env}" "${readlink_command}" "${sleep_command}"; do
  if [[ ! -x ${command_path} ]]; then
    printf 'ERROR: required command is not executable: %s\n' "${command_path}" >&2
    exit 2
  fi
done

if [[ ! ${attempts} =~ ^[1-9][0-9]*$ || ! ${interval} =~ ^[0-9]+$ ]]; then
  printf 'ERROR: attempts must be positive and interval must be non-negative\n' >&2
  exit 2
fi

profiles_directory=${system_profile%/*}

settled_generation() {
  local current_target
  local generation_link
  local generation_name
  local generation_target

  [[ -L ${system_profile} && -L ${current_system} ]] || return 1

  generation_name=$("${readlink_command}" "${system_profile}") || return 1
  generation_name=${generation_name##*/}
  [[ ${generation_name} =~ ^system-[0-9]+-link$ ]] || return 1

  generation_link="${profiles_directory}/${generation_name}"
  [[ -L ${generation_link} ]] || return 1

  generation_target=$("${readlink_command}" "${generation_link}") || return 1
  current_target=$("${readlink_command}" "${current_system}") || return 1
  [[ -n ${generation_target} && ${generation_target} == "${current_target}" ]] || return 1

  printf '%s\n' "${generation_name}"
}

generation_name=
for ((attempt = 1; attempt <= attempts; attempt++)); do
  if generation_name=$(settled_generation); then
    break
  fi

  if ((attempt < attempts)); then
    "${sleep_command}" "${interval}"
  fi
done

if [[ -z ${generation_name} ]]; then
  printf 'system activation has not settled; keeping system profile history\n' >&2
  exit 0
fi

shopt -s nullglob
old_generations=()
for generation_link in "${profiles_directory}"/system-*-link; do
  candidate_name=${generation_link##*/}
  [[ -L ${generation_link} && ${candidate_name} =~ ^system-([0-9]+)-link$ ]] || continue
  candidate_generation=${BASH_REMATCH[1]}
  [[ ${candidate_name} == "${generation_name}" ]] || old_generations+=("${candidate_generation}")
done

if ((${#old_generations[@]} == 0)); then
  exit 0
fi

if [[ $(settled_generation) != "${generation_name}" ]]; then
  printf 'system generation changed before pruning; keeping system profile history\n' >&2
  exit 0
fi

"${nix_env}" --profile "${system_profile}" --delete-generations "${old_generations[@]}"
