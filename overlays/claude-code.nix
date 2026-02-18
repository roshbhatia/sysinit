# overlays/claude-code.nix
# Purpose: expose Claude Code installed outside Nix.
{ ... }:

final: _prev: {
  claude-code = final.stdenvNoCC.mkDerivation {
    pname = "claude-code";
    version = "external";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/claude <<'EOF'
      #!/usr/bin/env bash
      exec claude "$@"
      EOF
      chmod +x $out/bin/claude
    '';
    meta = with final.lib; {
      description = "Claude Code CLI (provided by external install)";
      homepage = "https://claude.ai";
      license = licenses.unfree;
      mainProgram = "claude";
    };
  };
}
