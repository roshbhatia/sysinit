final: _prev:
let
  sources = final.nvfetcherSources;
  inherit (sources.atomic-coding-agent) version;

  platformInfo = {
    "aarch64-darwin" = sources.atomic-coding-agent.src;
    "x86_64-darwin" = sources.atomic-coding-agent-x86_64-darwin.src;
    "aarch64-linux" = sources.atomic-coding-agent-aarch64-linux.src;
    "x86_64-linux" = sources.atomic-coding-agent-x86_64-linux.src;
  };

  src =
    platformInfo.${final.stdenv.hostPlatform.system}
      or (throw "atomic-coding-agent: Unsupported platform ${final.stdenv.hostPlatform.system}");

  # The `PI_*` names atomic honours as legacy aliases for its own variables,
  # taken from its `docs/environment-variables.md` rather than from a grep, so
  # this list is what upstream says it reads and not what a string happens to
  # match. Seven configuration names and the five session names it overlays onto
  # a bash tool call.
  #
  # `PI_CACHE_RETENTION` is deliberately absent: atomic documents it as a
  # provider option with no atomic-prefixed alias, so it is shared on purpose.
  legacyPiAliases = [
    "PI_CODING_AGENT_DIR"
    "PI_CODING_AGENT_SESSION_DIR"
    "PI_PACKAGE_DIR"
    "PI_OFFLINE"
    "PI_SKIP_VERSION_CHECK"
    "PI_TELEMETRY"
    "PI_REDUCED_MOTION"
    "PI_SESSION_ID"
    "PI_SESSION_FILE"
    "PI_PROVIDER"
    "PI_MODEL"
    "PI_REASONING_LEVEL"
  ];
in
{
  atomic-coding-agent = final.stdenv.mkDerivation {
    pname = "atomic-coding-agent";
    inherit version src;

    sourceRoot = ".";

    nativeBuildInputs = [ final.makeWrapper ];

    # Wrapped rather than symlinked, because two pi-lineage agents share one
    # environment on this machine and precedence alone does not separate them.
    # Atomic prefers its own `ATOMIC_*` name when both are set, so an alias only
    # bites where the owner set the pi spelling and not the atomic one: then pi's
    # model, provider, session, or agent directory silently steers atomic.
    # Unsetting the aliases here closes that channel for every name at once.
    #
    # The two defaults repeat what `harnesses/atomic/default.nix` declares in
    # `sessionVariables`, on purpose. A shell that was already open when the
    # switch ran returns early from `hm-session-vars.sh` and never sees a new
    # session variable, which is how atomic came to read pi's whole agent
    # directory in the first place. A wrapper cannot be missed that way, and
    # `:-` keeps a deliberate override from the caller working.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp -r atomic $out/
      makeWrapper $out/atomic/atomic $out/bin/atomic \
        ${final.lib.concatMapStringsSep " " (name: "--unset ${name}") legacyPiAliases} \
        --run 'export ATOMIC_CODING_AGENT_DIR="''${ATOMIC_CODING_AGENT_DIR:-$HOME/.atomic/agent}"' \
        --run 'export ATOMIC_SKIP_VERSION_CHECK="''${ATOMIC_SKIP_VERSION_CHECK:-1}"'
      runHook postInstall
    '';

    # Proves the wrapper runs the payload rather than only existing. A wrapper
    # that unsets the wrong thing, or a `--run` line with a quoting error, fails
    # here instead of on the owner's next atomic session.
    doInstallCheck = true;
    installCheckPhase = ''
      runHook preInstallCheck
      got=$(PI_CODING_AGENT_DIR=/should/not/reach/atomic $out/bin/atomic --version 2>&1)
      case "$got" in
        *${version}*) ;;
        *)
          echo "atomic --version printed '$got', expected it to name ${version}" >&2
          exit 1
          ;;
      esac
      runHook postInstallCheck
    '';

    meta = with final.lib; {
      description = "Coding agent runtime with stages, checks, and approval gates";
      homepage = "https://github.com/bastani-inc/atomic";
      # `package.json` says MIT; GitHub reports NOASSERTION because the tarball
      # ships no LICENSE file. Taking the declaration in the package metadata.
      license = licenses.mit;
      mainProgram = "atomic";
    };
  };
}
