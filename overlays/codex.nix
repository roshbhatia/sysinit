_final: prev: {
  codex = prev.codex.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./codex-sanitize-terminal-output.patch ];
    doCheck = true;
    cargoTestFlags = [
      "--package"
      "codex-ansi-escape"
    ];
  });
}
