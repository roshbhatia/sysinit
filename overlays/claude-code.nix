_:

final: prev:
let
  version = "2.1.159";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-pA22JaIbvXr8ZATUQteC6K9VGQ76N3ieZeFAMKTXjRs="; # autoupdate:src-hash
  };
in
{
  claude-code = prev.claude-code.overrideAttrs (old: {
    inherit version src;
    postPatch = ''
      cp ${./claude-code-package-lock.json} package-lock.json
    '';
    npmDeps = prev.fetchNpmDeps {
      name = "claude-code-${version}-npm-deps";
      inherit src;
      postPatch = ''
        cp ${./claude-code-package-lock.json} package-lock.json
      '';
      hash = "sha256-ioD1K/jTTSb3bl8Xsz20O1TcTRLCtfpXbhZHvd183l0="; # autoupdate:npm-deps-hash
    };
  });
}
