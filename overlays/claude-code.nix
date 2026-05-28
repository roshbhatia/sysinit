_:

final: prev:
let
  version = "2.1.153";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-H54BHuEvmnpHQLLWox58qpZvn88CYSgO633ob7kW4Sk="; # autoupdate:src-hash
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
      hash = "sha256-T1R24n/qjJ3ygLWJtgKcgZCSkmE2vHtZyqwbFMiiZRw="; # autoupdate:npm-deps-hash
    };
  });
}
