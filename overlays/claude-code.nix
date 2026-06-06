_:

final: prev:
let
  version = "2.1.167";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-Yh8Ir4x3IuOkK19fn2q2xuxXtTjXAnEiwtDnGnfmmhg="; # autoupdate:src-hash
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
      hash = "sha256-VSB1nl1FZWD/OH9DD0ycQj1Oy+5onf7XJrDgerfj+mQ="; # autoupdate:npm-deps-hash
    };
  });
}
