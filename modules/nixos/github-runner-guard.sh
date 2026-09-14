set -euo pipefail

if [[ ${GITHUB_REPOSITORY:-} != roshbhatia/sysinit || ${GITHUB_REF:-} != refs/heads/main ]]; then
  echo "Arrakis accepts only roshbhatia/sysinit main jobs" >&2
  exit 1
fi
case "${GITHUB_EVENT_NAME:-}" in
  push | schedule | workflow_dispatch) ;;
  *)
    echo "Arrakis does not accept pull request jobs" >&2
    exit 1
    ;;
esac
