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
  };

  yarn = {
    bin = "${pkgs.yarn}/bin/yarn";
    env = ''
      export NODE_NO_WARNINGS=1
      export NODE_TLS_REJECT_UNAUTHORIZED=0
      export PATH="${pkgs.yarn}/bin:$PATH"
      export YARN_GLOBAL_FOLDER="$HOME/.yarn"
    '';
    installCmd = ''
      "$MANAGER_CMD" config set strict-ssl false -g
      "$MANAGER_CMD" global add "$pkg" --silent || echo "Warning: Failed to install $pkg"
    '';
  };
}
