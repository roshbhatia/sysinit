_final: prev: {
  codex = prev.codex.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./codex-sanitize-terminal-output.patch
      ./codex-mcp-capabilities.patch
    ];
    doCheck = true;
    cargoTestFlags = [
      "--package"
      "codex-ansi-escape"
    ];
  });
}
