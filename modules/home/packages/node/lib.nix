{ pkgs }:

{
  npm = {
    bin = "${pkgs.nodejs}/bin/npm";
    env = ''
      export NODE_NO_WARNINGS=1
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export PATH="${pkgs.nodejs}/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.npm-global"
    '';
    installCmd = ''"$MANAGER_CMD" install -g "$pkg" --silent || echo "Warning: Failed to install $pkg"'';
    cleanupCmd = ''
      comm -23 <("$MANAGER_CMD" -g list --depth=0 2>/dev/null | awk '{print $1}' | grep -v "^$" | sort) <(sort "$managed_pkg_file") | while read pkg; do
        [ -n "$pkg" ] && "$MANAGER_CMD" -g remove "$pkg" 2>/dev/null || true
      done
    '';
  };

  yarn = {
    bin = "${pkgs.yarn}/bin/yarn";
    env = ''
      export NODE_NO_WARNINGS=1
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export PATH="${pkgs.yarn}/bin:$PATH"
      export YARN_GLOBAL_FOLDER="$HOME/.yarn"
    '';
    setupCmd = ''
      "$MANAGER_CMD" config set strict-ssl false -g 2>/dev/null || true
    '';
    installCmd = ''
      "$MANAGER_CMD" global add "$pkg" --silent 2>/dev/null || echo "Warning: Failed to install $pkg"
    '';
    cleanupCmd = ''
      comm -23 <("$MANAGER_CMD" global list 2>/dev/null | awk '{print $1}' | grep -v "^$" | sort) <(sort "$managed_pkg_file") | while read pkg; do
        [ -n "$pkg" ] && "$MANAGER_CMD" global remove "$pkg" 2>/dev/null || true
      done
    '';
  };
}
