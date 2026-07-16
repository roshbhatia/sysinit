_:

final: prev:
let
  version = "2.1.211";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-SvLwxHXYRBlFI8//BsuyNimPkoecB0rr02oOCCZqTWM="; # autoupdate:src-hash
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
      hash = "sha256-gQ8T8wa24elZu9xxh7QDmbNL93Bk6j58zZHaHpz3fPc="; # autoupdate:npm-deps-hash
    };
  });
}
