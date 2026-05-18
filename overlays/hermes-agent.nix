_:

# Hermes — Nous Research agent CLI. Slim packaging: zero optional extras.
# Native providers (anthropic, gemini, copilot, copilot-acp, etc.) all work
# without the [anthropic]/[all] extras per the upstream provider matrix.
#
# Bumping the pin: fetch latest URL + sha256 via
#   curl -sL https://pypi.org/pypi/hermes-agent/<ver>/json \
#     | jq '.urls[] | select(.filename | endswith(".tar.gz")) | {url, sha256: .digests.sha256}'
# then update `version` + `sha256` below.
#
# Architectural precedent: overlays/cocoindex-code.nix.

final: _prev:
let
  version = "0.14.0";

  src = final.fetchurl {
    url = "https://files.pythonhosted.org/packages/78/ac/0535aab709872130fca6118256315164704d92a7427be116984e6e0e3997/hermes_agent-${version}.tar.gz";
    sha256 = "8f2c14125990b305eab4e29c23e180391805cb81b1d7b3da38447e29095eda4b";
  };

  python = final.python3;

  # Subagent binaries reachable via PATH from any hermes invocation.
  # Build-time guarantee: hermes never depends on the user's interactive
  # shell having these on PATH. If a future bundled skill needs a binary
  # not in this list, add the corresponding derivation here.
  subagentBins = [
    "${final.claude-code}/bin"
    "${final.codex-acp}/bin"
    "${final.opencode}/bin"
    "${final.github-copilot-cli}/bin"
    "${final.gh}/bin"
    "${final.gemini-cli}/bin"
  ];

  unwrapped = python.pkgs.buildPythonApplication {
    pname = "hermes-agent-unwrapped";
    inherit version src;
    pyproject = true;

    build-system = with python.pkgs; [
      setuptools
    ];

    # Upstream pins every core dep to an exact `==X.Y.Z` for supply-chain
    # hardening (rationale in hermes-agent pyproject.toml). nixpkgs-unstable
    # tends to carry newer versions; relax all pins and accept divergence —
    # this is a single-user dotfile install, not a hardened fleet build.
    pythonRelaxDeps = true;

    dependencies = with python.pkgs; [
      openai
      python-dotenv
      fire
      httpx
      # `httpx[socks]` upstream → relies on httpx-socks at runtime; nixpkgs
      # ships it separately rather than as an httpx extra.
      httpx-socks
      rich
      tenacity
      pyyaml
      ruamel-yaml
      requests
      jinja2
      pydantic
      prompt-toolkit
      croniter
      pyjwt
      # `PyJWT[crypto]` upstream → cryptography is the underlying dep.
      cryptography
      psutil
    ];

    # Upstream sdist exposes flat top-level modules (`agent`, `providers`,
    # `hermes_cli`, ...) rather than a `hermes_agent` namespace package, so
    # the standard `pythonImportsCheck` doesn't fit. Smoke-test via the
    # wrapped `hermes` binary at runtime instead.
    doCheck = false;

    meta = with final.lib; {
      description = "Nous Research AI agent CLI with bundled multi-agent skills (slim — no optional extras)";
      homepage = "https://hermes-agent.nousresearch.com/";
      license = licenses.mit;
      mainProgram = "hermes";
    };
  };
in
{
  hermes-agent = final.symlinkJoin {
    name = "hermes-agent-${version}";
    paths = [ unwrapped ];
    nativeBuildInputs = [ final.makeWrapper ];

    # wrapProgram prepends subagent derivations onto PATH so bundled
    # autonomous-AI-agent skills (claude-code, codex, opencode) and the
    # Copilot ACP provider find their binaries regardless of the caller's
    # environment.
    postBuild = ''
      wrapProgram $out/bin/hermes \
        --prefix PATH : ${final.lib.concatStringsSep ":" subagentBins}
    '';

    meta = unwrapped.meta;
  };
}
