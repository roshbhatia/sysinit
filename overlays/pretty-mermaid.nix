final: prev:
let
  # Pinned by rev because the upstream publishes no tags. `hack/update-pretty-mermaid.sh`
  # moves the pin and both hashes, so drift is a diff rather than a silent upgrade.
  rev = "e33f086d3b5bcec9f28632e4bd9c348b02bb2278"; # autoupdate:rev
  src = prev.fetchFromGitHub {
    owner = "imxv";
    repo = "Pretty-mermaid-skills";
    inherit rev;
    hash = "sha256-AwffzL8lbYLJ6KNXJr2PBLGhd2Wv0cOjziU8fNENEMQ="; # autoupdate:src-hash
  };

  # The upstream ships no lockfile, and `fetchNpmDeps` needs one.
  lock = ./pretty-mermaid-package-lock.json;
in
{
  pretty-mermaid = prev.buildNpmPackage {
    pname = "pretty-mermaid";
    version = "0.1.3-${builtins.substring 0 7 rev}";
    inherit src;

    postPatch = ''
      cp ${lock} package-lock.json
    '';

    npmDeps = prev.fetchNpmDeps {
      name = "pretty-mermaid-npm-deps";
      inherit src;
      postPatch = ''
        cp ${lock} package-lock.json
      '';
      hash = "sha256-FsXptq/nC82o854MoVszQPjzBYvNuh1WxF4+OiA2SPk="; # autoupdate:npm-deps-hash
    };

    dontNpmBuild = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/pretty-mermaid
      cp -r scripts node_modules package.json $out/lib/pretty-mermaid/

      # Three entry points rather than one dispatcher, because the upstream scripts
      # take different flags and a dispatcher would have to keep its own copy of them.
      for pair in "pretty-mermaid:render" "pretty-mermaid-batch:batch" "pretty-mermaid-themes:themes"; do
        name=''${pair%%:*}
        script=''${pair##*:}
        makeWrapper ${prev.nodejs}/bin/node $out/bin/$name \
          --add-flags $out/lib/pretty-mermaid/scripts/$script.mjs
      done

      runHook postInstall
    '';

    nativeBuildInputs = [ prev.makeWrapper ];

    meta = with final.lib; {
      description = "Render mermaid diagrams as themed SVG or ASCII, offline";
      homepage = "https://github.com/imxv/Pretty-mermaid-skills";
      license = licenses.mit;
      mainProgram = "pretty-mermaid";
    };
  };
}
