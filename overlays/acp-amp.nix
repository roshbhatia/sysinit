final: prev: {
  # Amp has no ACP mode of its own, so the bridge is a third-party adapter. It is
  # not in nixpkgs, and it wants Python 3.10 or newer, so uv owns the environment
  # the same way cua and basic-memory do in modules/home/programs/llm.
  #
  # The version is pinned: uvx keys its cache on the requirement string, so an
  # unpinned one re-resolves on every upstream release.
  acp-amp = prev.writeShellScriptBin "acp-amp" ''
    set -euo pipefail

    export PATH="${prev.lib.makeBinPath [ final.uv ]}:$PATH"
    export UV_PYTHON="${final.python313}/bin/python3"
    export UV_PYTHON_DOWNLOADS=never

    exec ${final.uv}/bin/uvx "acp-amp==0.1.3" "$@"
  '';
}
