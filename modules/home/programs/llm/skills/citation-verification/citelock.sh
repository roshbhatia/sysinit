#!/usr/bin/env bash

set -euo pipefail

LOCKFILE_NAME="citations.lock"
SNAP_DIR_NAME="citations"

freshness_days() {
  case "$1" in
    pricing | availability) echo 30 ;;
    api) echo 90 ;;
    paper) echo 0 ;;
    *) echo 180 ;;
  esac
}

log() { echo "citelock: $*" >&2; }
die() {
  echo "citelock: ERROR: $*" >&2
  exit 1
}

require_tool() {
  command -v "$1" > /dev/null 2>&1 || die "required tool not on PATH: $1"
}

anchor_contains() {
  awk 'BEGIN { q = ENVIRON["CITELOCK_Q"] } { b = b $0 ORS } END { exit index(b, q) ? 0 : 1 }' "$1"
}

sha256_of() {
  if command -v sha256sum > /dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  else
    shasum -a 256 "$1" | awk '{print $1}'
  fi
}

assert_safe_url() {
  local url="$1" host
  case "$url" in
    https://*) ;;
    *) die "refusing non-https source (scheme allowlist): $url" ;;
  esac
  host="${url#https://}"
  host="${host%%/*}" # strip path
  host="${host##*@}" # strip userinfo (user:pass@) before matching
  host="${host%%:*}" # strip port
  case "$host" in
    "") die "could not parse host from URL: $url" ;;
    localhost | localhost. | *.localhost) die "refusing loopback host: $host" ;;
    \[*) die "refusing IPv6-literal host: $host" ;;
    metadata.google.internal | *.internal) die "refusing internal/metadata host: $host" ;;
    127.* | 0.* | 169.254.* | 10.* | 192.168.*) die "refusing loopback/link-local/RFC-1918 host: $host" ;;
    172.1[6-9].* | 172.2[0-9].* | 172.3[0-1].*) die "refusing RFC-1918 host: $host" ;;
    0x* | *.0x*) die "refusing hex-IP host: $host" ;;
    *[!0-9.]*) : ;;                                               # has a non-numeric char -> DNS name, allowed
    *) die "refusing numeric-IP host (cite a DNS name): $host" ;; # all digits/dots: dotted or decimal IP
  esac
}

lock_path() { echo "$1/${LOCKFILE_NAME}"; }

verify() {
  local lockdir="${1:-.}"
  local lock
  lock="$(lock_path "$lockdir")"

  if [[ ! -f ${lock} ]]; then
    log "no ${LOCKFILE_NAME} in ${lockdir}; nothing to verify (no-op)"
    return 0
  fi
  require_tool jq

  local ids failed=0 today_epoch
  today_epoch="$(date +%s)"
  ids="$(jq -r '.records[].id' "$lock")"

  local id
  while IFS= read -r id; do
    [[ -z ${id} ]] && continue
    local rec source quote snap sha accessed class prov
    rec="$(jq -c --arg id "$id" '.records[] | select(.id==$id)' "$lock")"
    source="$(jq -r '.source // ""' <<< "$rec")"
    quote="$(jq -r '.quote // ""' <<< "$rec")"
    snap="$(jq -r '.snapshot // ""' <<< "$rec")"
    sha="$(jq -r '.sha256 // ""' <<< "$rec")"
    accessed="$(jq -r '.accessed // ""' <<< "$rec")"
    class="$(jq -r '.claim_class // ""' <<< "$rec")"

    if [[ -z ${source} || -z ${quote} || -z ${snap} || -z ${sha} || -z ${accessed} || -z ${class} ]]; then
      log "[$id] format: missing required field (source/quote/snapshot/sha256/accessed/claim_class)"
      failed=1
      continue
    fi

    local snap_file="${lockdir}/${snap}"
    prov="${snap_file}.prov.json"

    if [[ ! -f ${snap_file} ]]; then
      log "[$id] snapshot missing: ${snap_file}"
      failed=1
      continue
    fi
    if [[ ! -f ${prov} ]]; then
      log "[$id] no capture provenance sidecar (${snap}.prov.json); hand-authored snapshots are rejected"
      failed=1
      continue
    fi

    local actual
    actual="$(sha256_of "$snap_file")"
    if [[ ${actual} != "$sha" ]]; then
      log "[$id] integrity: snapshot sha256 mismatch (recorded ${sha}, actual ${actual})"
      failed=1
      continue
    fi
    local prov_sha
    prov_sha="$(jq -r '.sha256 // ""' "$prov")"
    if [[ ${prov_sha} != "$sha" ]]; then
      log "[$id] integrity: provenance sha256 does not match record"
      failed=1
      continue
    fi

    if ! CITELOCK_Q="$quote" anchor_contains "$snap_file"; then
      log "[$id] unanchored: verbatim quote not found in snapshot"
      failed=1
      continue
    fi

    local max_days
    max_days="$(freshness_days "$class")"
    if [[ ${max_days} -gt 0 ]]; then
      local acc_epoch age_days
      acc_epoch="$(date -j -f "%Y-%m-%d" "$accessed" +%s 2> /dev/null || date -d "$accessed" +%s 2> /dev/null || echo 0)"
      if [[ ${acc_epoch} -eq 0 ]]; then
        log "[$id] freshness: unparseable accessed date '${accessed}'"
        failed=1
        continue
      fi
      age_days=$(((today_epoch - acc_epoch) / 86400))
      if [[ ${age_days} -gt ${max_days} ]]; then
        log "[$id] stale: ${class} claim accessed ${age_days}d ago (max ${max_days}d)"
        failed=1
        continue
      fi
    fi
  done <<< "$ids"

  if [[ ${failed} -ne 0 ]]; then
    die "offline gate failed for ${lock}"
  fi
  log "offline gate passed: ${lock}"
}

live_checks() {
  local url="$1" doi="${2:-}"
  if [[ ${CITELOCK_OFFLINE:-0} == 1 ]]; then
    log "CITELOCK_OFFLINE=1: skipping live checks (advisory)"
    return 0
  fi
  if command -v lychee > /dev/null 2>&1; then
    if ! lychee --no-progress --max-retries 1 -- "$url" > /dev/null 2>&1; then
      if command -v pplx > /dev/null 2>&1 &&
        pplx content fetch "$url" > /dev/null 2>&1; then
        log "live: lychee could not confirm ${url}; pplx fetched it, treating as live"
      else
        log "live: neither lychee nor pplx could confirm ${url} (dead link or transient); treat as fail at capture"
        return 1
      fi
    fi
  elif command -v pplx > /dev/null 2>&1; then
    if ! pplx content fetch "$url" > /dev/null 2>&1; then
      log "live: pplx could not fetch ${url} (dead link or transient); treat as fail at capture"
      return 1
    fi
  else
    log "live: neither lychee nor pplx on PATH; skipping liveness"
  fi
  if [[ -n ${doi} ]] && command -v jq > /dev/null 2>&1; then
    local resp
    if resp="$(curl -fsS --max-time 20 "https://api.crossref.org/works/${doi}" 2> /dev/null)"; then
      local updates
      updates="$(jq -r '[.message."update-to"[]? | select(.type=="retraction")] | length' <<< "$resp" 2> /dev/null || echo 0)"
      if [[ ${updates} -gt 0 ]]; then
        log "live: DOI ${doi} is retracted (Crossref update-to)"
        return 1
      fi
    else
      log "live: Crossref lookup for ${doi} failed (nonexistent DOI or transient)"
      return 1
    fi
  fi
  return 0
}

capture() {
  local url="" id="" quote="" class="" doi="" lockdir="."
  url="$1"
  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --id)
        id="$2"
        shift 2
        ;;
      --quote)
        quote="$2"
        shift 2
        ;;
      --class)
        class="$2"
        shift 2
        ;;
      --doi)
        doi="$2"
        shift 2
        ;;
      --lockdir)
        lockdir="$2"
        shift 2
        ;;
      *) die "unknown capture flag: $1" ;;
    esac
  done
  [[ -n ${id} && -n ${quote} && -n ${class} ]] || die "capture requires --id, --quote, --class"
  assert_safe_url "$url"
  require_tool jq

  local snap_rel="${SNAP_DIR_NAME}/${id}.snapshot"
  local snap_file="${lockdir}/${snap_rel}"
  local prov="${snap_file}.prov.json"
  mkdir -p "${lockdir}/${SNAP_DIR_NAME}"

  local tmp status
  tmp="$(mktemp)"
  if command -v monolith > /dev/null 2>&1; then
    monolith --no-audio --no-video --no-frames --silent --output "$tmp" -- "$url" 2> /dev/null || : > "$tmp"
  fi
  if [[ ! -s ${tmp} ]]; then
    require_tool curl
    curl -fsS --max-redirs 0 --max-time 30 -o "$tmp" -- "$url" || die "capture: fetch failed (or redirected) for ${url}"
  fi
  status=200

  if ! CITELOCK_Q="$quote" anchor_contains "$tmp"; then
    rm -f "$tmp"
    die "capture: quote does not anchor in fetched content for ${id}. If this is a client-rendered page, cite a stable/archived URL or the underlying JSON API."
  fi

  mv "$tmp" "$snap_file"
  local sha
  sha="$(sha256_of "$snap_file")"
  jq -n --arg url "$url" --arg status "$status" --arg sha "$sha" --arg engine "$(command -v monolith > /dev/null 2>&1 && echo monolith || echo curl)" \
    '{url:$url, http_status:($status|tonumber), engine:$engine, sha256:$sha}' > "$prov"

  live_checks "$url" "$doi" || die "capture: live-web check failed for ${id}"

  local lock
  lock="$(lock_path "$lockdir")"
  [[ -f ${lock} ]] || echo '{"records":[]}' > "$lock"
  local accessed
  accessed="$(date +%Y-%m-%d)"
  local tmp_lock
  tmp_lock="$(mktemp)"
  jq --arg id "$id" --arg source "$url" --arg doi "$doi" --arg accessed "$accessed" \
    --arg class "$class" --arg quote "$quote" --arg snap "$snap_rel" --arg sha "$sha" \
    '.records |= (map(select(.id != $id)) + [({
       id:$id, source:$source, accessed:$accessed,
       claim_class:$class, quote:$quote, snapshot:$snap, sha256:$sha
     } + (if $doi != "" then {doi:$doi} else {} end))])' "$lock" > "$tmp_lock"
  mv "$tmp_lock" "$lock"
  log "captured [$id] -> ${snap_rel} (sha ${sha:0:12})"
}

recheck() {
  local lockdir="${1:-.}"
  local lock
  lock="$(lock_path "$lockdir")"
  [[ -f ${lock} ]] || {
    log "no ${LOCKFILE_NAME} in ${lockdir}; nothing to recheck"
    return 0
  }
  require_tool jq
  local n failed=0
  n="$(jq '.records | length' "$lock")"
  local i
  for ((i = 0; i < n; i++)); do
    local url doi id
    url="$(jq -r ".records[$i].source" "$lock")"
    doi="$(jq -r ".records[$i].doi // \"\"" "$lock")"
    id="$(jq -r ".records[$i].id" "$lock")"
    assert_safe_url "$url"
    live_checks "$url" "$doi" || {
      log "[$id] recheck failed"
      failed=1
    }
  done
  [[ ${failed} -eq 0 ]] || die "recheck found dead/retracted sources in ${lock}"
  log "recheck passed: ${lock}"
}

main() {
  local cmd="${1:-verify}"
  shift || true
  case "$cmd" in
    verify) verify "${1:-.}" ;;
    capture)
      [[ $# -ge 1 ]] || die "capture requires a URL"
      capture "$@"
      ;;
    recheck) recheck "${1:-.}" ;;
    *) die "unknown command: ${cmd} (verify|capture|recheck)" ;;
  esac
}

main "$@"
