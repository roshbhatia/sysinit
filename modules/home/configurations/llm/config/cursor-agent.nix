{
  lib,
  pkgs,
  ...
}:
let
  cursorConfig = builtins.toJSON {
    version = 1;
    permissions = {
      allow = [ "Shell(ls)" ];
      deny = [ ];
    };
    editor = {
      vimMode = true;
    };
    network = {
      useHttp1ForAgent = true;
    };
  };
in
{
  home.activation.cursorCliConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        ${pkgs.curl}/bin/curl -k https://cursor.com/install -fsS | bash

        $DRY_RUN_CMD mkdir -p "$HOME/.config/cursor"
        $DRY_RUN_CMD mkdir -p "$HOME/.cursor"

        cat > "$HOME/.config/cursor/cli-config.json" << 'EOF'
    ${cursorConfig}
    EOF

        cat > "$HOME/.cursor/cli-config.json" << 'EOF'
    ${cursorConfig}
    EOF
  '';
}
