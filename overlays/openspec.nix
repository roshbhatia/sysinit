{ ... }:

final: _prev: {
  openspec = final.stdenvNoCC.mkDerivation {
    pname = "openspec";
    version = "external";
    dontUnpack = true;
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/openspec <<'EOF'
      #!/usr/bin/env bash
      exec openspec "$@"
      EOF
      chmod +x $out/bin/openspec
    '';
    meta = with final.lib; {
      description = "OpenSpec CLI (provided by external install)";
      homepage = "https://github.com/Fission-AI/OpenSpec";
      license = licenses.mit;
      mainProgram = "openspec";
    };
  };
}
