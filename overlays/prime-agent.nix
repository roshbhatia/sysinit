final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.prime-agent) version;

  # prime-agent's release asset is an npm tarball, not the per-platform prebuilt binary
  # that `pi-coding-agent.nix` and `atomic-coding-agent.nix` extract.
  nodeDeps = {
    zeromq = {
      version = "6.5.0"; # prime-agent asks for ^6.1.2
      hash = "sha256-Mwq6wkLDp7hndz7CAFb45ZAso5C0Bc6z1gDaG4L9uBw=";
    };
    cmake-ts = {
      version = "1.0.2"; # zeromq pins this exactly
      hash = "sha256-5hZnCu06bdnM+Sm3lB9oEI4cmlLkl52gqsfred+niIU=";
    };
    undici = {
      version = "7.29.0"; # prime-agent asks for ^7.28.0
      hash = "sha256-7CAF2CJzR2X8CMPuXVCx9yC/HD/GI1qwKOXMYchaOnA=";
    };
  };

  fetchNpm =
    name:
    { version, hash }:
    final.fetchurl {
      url = "https://registry.npmjs.org/${name}/-/${name}-${version}.tgz";
      inherit hash;
    };

  nodeDepTarballs = final.lib.mapAttrsToList (name: spec: {
    inherit name;
    tarball = fetchNpm name spec;
  }) nodeDeps;
in
{
  prime-agent = final.stdenv.mkDerivation {
    pname = "prime-agent";
    inherit version;
    inherit (sources.prime-agent) src;

    # The tarball unpacks to `package/`, which is where every path below is
    # relative to.
    sourceRoot = "package";

    nativeBuildInputs = [ final.makeWrapper ];

    # The payload is bundled JavaScript plus zeromq's prebuilt `addon.node` for every
    # platform it ships.
    dontStrip = true;
    dontPatchELF = true;

    installPhase = ''
      runHook preInstall

      mkdir -p $out/lib/prime-agent
      cp -r . $out/lib/prime-agent/

      mkdir -p $out/lib/prime-agent/node_modules
      ${final.lib.concatMapStringsSep "\n" (dep: ''
        mkdir -p "$out/lib/prime-agent/node_modules/${dep.name}"
        tar -xzf ${dep.tarball} -C "$out/lib/prime-agent/node_modules/${dep.name}" --strip-components=1
      '') nodeDepTarballs}

      # `postinstall.cjs` is a no-op unless one of the bootstrap variables is
      # set, and both of the things it would bootstrap (ripgrep, fd, a uv-managed
      # python) belong to the wrapper below rather than to a build-time download.
      rm -f $out/lib/prime-agent/postinstall.cjs

      # `uv` is on PATH because the `ipython` tool is prime-agent's headline
      # feature and `dist/core/kernel/bootstrap.js` needs uv to build its kernel
      # venv. `PRIME_AGENT_INSTALL_UV=0` is what stops the fallback: without it,
      # a missing uv makes prime-agent offer to run astral.sh's curl installer,
      # which would write a binary outside the store.
      #
      # The venv itself lands in `~/.prime/agent/kernel-venv` on first use and
      # needs the network once. Nix does not manage it: it holds ipykernel, a
      # version-matched `prime-agent-runtime`, and whatever python packages a
      # session installs, so it is session state like `auth.json`, not config.
      #
      # The last two lines are the isolation from the other two pi-lineage
      # agents. Unlike atomic, prime-agent publishes no prefixed alias for
      # `PI_SKIP_VERSION_CHECK`: the fork reads that literal name, so unsetting
      # the pi spelling would take a knob away rather than separate anything.
      # Setting it here instead ends the cross-module dependency, where
      # prime-agent's startup behaviour came from a session variable the pi module
      # owns and could change without prime-agent noticing. `:-` leaves both an
      # owner override and the agent directory's own default reachable.
      makeWrapper ${final.nodejs_22}/bin/node $out/bin/prime-agent \
        --add-flags $out/lib/prime-agent/dist/bundle/cli.js \
        --prefix PATH : ${
          final.lib.makeBinPath [
            final.fd
            final.ripgrep
            final.uv
          ]
        } \
        --set PRIME_AGENT_INTERACTIVE_SELF_UPDATE 0 \
        --set PRIME_AGENT_INSTALL_UV 0 \
        --run 'export PRIME_AGENT_CODING_AGENT_DIR="''${PRIME_AGENT_CODING_AGENT_DIR:-$HOME/.prime/agent}"' \
        --run 'export PI_SKIP_VERSION_CHECK="''${PI_SKIP_VERSION_CHECK:-1}"'

      runHook postInstall
    '';

    # Proves the wrapper resolves node, the bundle, and all three vendored
    # dependencies. A missing one fails here rather than on first use, which is
    # the whole reason the set above was measured instead of guessed.
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      # prime-agent prints its version on stderr, so a plain capture is empty.
      got=$($out/bin/prime-agent --version 2>&1)
      if [ "$got" != "${version}" ]; then
        echo "prime-agent --version printed '$got', expected '${version}'" >&2
        exit 1
      fi
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Self-improving RLM coding agent, a pi fork with an IPython tool";
      homepage = "https://github.com/PrimeIntellect-ai/prime-agent";
      license = licenses.mit;
      mainProgram = "prime-agent";
      platforms = platforms.unix;
    };
  };
}
