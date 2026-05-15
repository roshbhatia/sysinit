_:

final: prev:
let
  version = "2.1.142";
  src = prev.fetchzip {
    url = "https://registry.npmjs.org/@anthropic-ai/claude-code/-/claude-code-${version}.tgz";
    hash = "sha256-H6mjQ5kGHUmoH6+FKm5urDVzVSF/9x9ct2iMNpQfiX8="; # autoupdate:src-hash
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
      hash = "sha256-nAvYJNVo0qKjpTUTwjzR749zpkfEULssdTuMfyplITk="; # autoupdate:npm-deps-hash
    };
  });
}
