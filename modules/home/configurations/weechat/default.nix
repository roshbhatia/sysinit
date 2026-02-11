{
  pkgs,
  lib,
  ...
}:

let
  weechatMatrixVenvDir = "$HOME/.local/share/weechat-matrix-venv";
  weechatMatrixSrc = pkgs.fetchFromGitHub {
    owner = "poljar";
    repo = "weechat-matrix";
    rev = "feae9fda26ea9de98da9cd6733980a203115537e";
    sha256 = "sha256-flv1XF0tZgu3qoMFfJZ2MzeHYI++t12nkq3jJkRiCQ0=";
  };

  # Script to bootstrap the weechat-matrix venv with uv
  setupScript = pkgs.writeShellScript "setup-weechat-matrix" ''
    set -euo pipefail
    VENV_DIR="${weechatMatrixVenvDir}"
    WEECHAT_PYTHON_DIR="$HOME/.local/share/weechat/python/autoload"

    # Create venv if it doesn't exist
    if [ ! -d "$VENV_DIR" ]; then
      echo "Creating weechat-matrix venv..."
      ${lib.getExe pkgs.uv} venv "$VENV_DIR" --python ${pkgs.python3}/bin/python3
    fi

    # Install dependencies from the source's requirements
    echo "Installing weechat-matrix dependencies..."
    ${lib.getExe pkgs.uv} pip install --python "$VENV_DIR/bin/python" \
      -r ${weechatMatrixSrc}/requirements.txt

    # Symlink matrix.py into weechat's autoload directory
    mkdir -p "$WEECHAT_PYTHON_DIR"
    ln -sf ${weechatMatrixSrc}/main.py "$WEECHAT_PYTHON_DIR/matrix.py"

    echo "weechat-matrix setup complete."
  '';
in
{
  home.packages = [
    (pkgs.wrapWeechat pkgs.weechat-unwrapped {
      configure =
        { availablePlugins, ... }:
        {
          plugins = (builtins.attrValues (builtins.removeAttrs availablePlugins [ "php" ]));
          scripts = with pkgs.weechatScripts; [
            colorize_nicks
            edit
            url_hint
            weechat-autosort
            weechat-grep
          ];
        };
    })
  ];

  # Run the setup script on activation
  home.activation.weechatMatrix = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${setupScript}
  '';

  # Ensure weechat sees the venv's site-packages
  home.sessionVariables = {
    WEECHAT_EXTRA_LIBDIR = "${weechatMatrixVenvDir}/lib";
  };
}
