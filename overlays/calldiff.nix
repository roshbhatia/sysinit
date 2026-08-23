final: prev:
let
  version = "0.5.0";

  # A bundle, not the upstream repo. calldiff ships only to npm, and its grammar
  # loader shells out to `npm install --prefix ~/.cache/calldiff/grammars` the
  # first time it meets a language. That is a network call and a home-directory
  # write triggered by an agent's shell command. `loadGrammarPackage` tries
  # `createRequire(import.meta.url)` before that cache, so a grammar sitting in
  # calldiff's own node_modules wins and the npm path never runs. This package.json
  # names the grammars for the languages this repo holds, plus python and rust.
  #
  # The tarballs carry prebuilt .node addons for six platforms, so nothing here
  # needs node-gyp and `npm ci --ignore-scripts` is enough. Grammars outside this
  # list still fall back to the runtime cache, which keeps calldiff usable in a
  # repo written in something else.
  src = ./calldiff;

  # node-gyp-build resolves prebuilds/<platform>-<arch> at require time, so the
  # other five are dead weight worth about 36 MiB. null keeps them all, which is
  # what an unrecognised system needs.
  keepPrebuild =
    {
      aarch64-darwin = "darwin-arm64";
      x86_64-darwin = "darwin-x64";
      aarch64-linux = "linux-arm64";
      x86_64-linux = "linux-x64";
    }
    .${final.stdenv.hostPlatform.system} or null;
in
{
  calldiff = prev.buildNpmPackage {
    pname = "calldiff";
    inherit version src;

    npmDeps = prev.fetchNpmDeps {
      name = "calldiff-npm-deps";
      inherit src;
      hash = "sha256-7TJmIoccEd16xskB5fOveIzjZi0Srwad8TrwBhfc0Dc=";
    };

    npmFlags = [ "--legacy-peer-deps" ];
    dontNpmBuild = true;

    nativeBuildInputs = [
      prev.makeWrapper
    ]
    ++ prev.lib.optional prev.stdenv.hostPlatform.isLinux prev.autoPatchelfHook;

    buildInputs = prev.lib.optional prev.stdenv.hostPlatform.isLinux prev.stdenv.cc.cc.lib;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/calldiff
      cp -r node_modules package.json $out/lib/calldiff/

      # calldiff maps .sh and .bash but not .zsh, and the bash grammar parses this
      # repo's zsh, including its dotted function names. Twelve files here were
      # unreadable for want of one extension.
      substituteInPlace $out/lib/calldiff/node_modules/calldiff/dist/languages/bash.js \
        --replace-fail '[".sh", ".bash"]' '[".sh", ".bash", ".zsh"]'

    ''
    + prev.lib.optionalString (keepPrebuild != null) ''
      find $out/lib/calldiff/node_modules -type d -path '*/prebuilds/*' \
        -not -name ${keepPrebuild} -maxdepth 4 -exec rm -rf {} +
    ''
    + ''
      makeWrapper ${prev.nodejs}/bin/node $out/bin/calldiff \
        --add-flags $out/lib/calldiff/node_modules/calldiff/dist/cli.js

      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Diff call stacks across git trees, with the grammars prebundled";
      homepage = "https://github.com/tanishqkancharla/calldiff";
      license = licenses.mit;
      mainProgram = "calldiff";
      platforms = platforms.unix;
    };
  };
}
