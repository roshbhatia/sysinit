_:

final: _prev:
let
  cocoindexVersion = "1.0.5";
  cocoindexCodeVersion = "0.2.33";

  # Pre-built Rust+PyO3 wheel from PyPI (cp311-abi3 → ABI-stable across 3.11+).
  # Per-platform hashes; bump together via:
  #   curl -sL https://pypi.org/pypi/cocoindex/json | jq '.releases."<ver>"[] | {filename, url, sha256: .digests.sha256}'
  cocoindexWheels = {
    "aarch64-darwin" = {
      path = "e9/c6/f1ea0d86fdece8a358246bdb3eb10be301b205a6a8c0bb835d261e2d151b";
      file = "cocoindex-${cocoindexVersion}-cp311-abi3-macosx_11_0_arm64.whl";
      sha256 = "b7fd9f16108370092d51c4ea2aab00a5bcd55568de3223eb7e94b1deb6c97aa8";
    };
    "x86_64-darwin" = {
      path = "5b/43/b3e1f280b8c4f55403e2f6a0a28cff52dde810b71f9f77d3aee86b47ed47";
      file = "cocoindex-${cocoindexVersion}-cp311-abi3-macosx_10_12_x86_64.whl";
      sha256 = "c34eb8bef6ff781f798302d486cbbc4dfa39f1b0d75b11ecfa04b1710cce79e8";
    };
    "aarch64-linux" = {
      path = "fa/41/aff9ddc2402b58723b731e3c601fd3344cc056edad9403cc30adc94f2d04";
      file = "cocoindex-${cocoindexVersion}-cp311-abi3-manylinux_2_28_aarch64.whl";
      sha256 = "84aa25874a47158f70fc691dc29bbf1f54f167d223e781c9d6f6d562e24ce493";
    };
    "x86_64-linux" = {
      path = "30/cf/0dd7e80a5fca62f7b5f08f335a1247ec9ac230f129ce1be4c4e23f34762c";
      file = "cocoindex-${cocoindexVersion}-cp311-abi3-manylinux_2_28_x86_64.whl";
      sha256 = "76d95854f8d55e575d728ae91462d2103dc7db6eeb39a9d040e364a74f38f22e";
    };
  };

  pickWheel =
    let
      sys = final.stdenv.hostPlatform.system;
      entry = cocoindexWheels.${sys} or (throw "cocoindex: unsupported platform ${sys}");
    in
    final.fetchurl {
      url = "https://files.pythonhosted.org/packages/${entry.path}/${entry.file}";
      sha256 = entry.sha256;
    };

  python = final.python3;

  cocoindex = python.pkgs.buildPythonPackage {
    pname = "cocoindex";
    version = cocoindexVersion;
    format = "wheel";
    src = pickWheel;

    # Slim variant — `[litellm]` extra enables cloud embeddings via the
    # litellm proxy at runtime. No torch / sentence-transformers / faiss
    # in the closure; users supplying their own API key drive embeddings.
    propagatedBuildInputs = with python.pkgs; [
      typing-extensions
      click
      rich
      python-dotenv
      watchdog
      numpy
      psutil
      msgspec
      litellm
    ];

    pythonImportsCheck = [ "cocoindex" ];

    meta = with final.lib; {
      description = "Incremental, real-time data transformation framework with Rust core";
      homepage = "https://cocoindex.io/";
      license = licenses.asl20;
      platforms = builtins.attrNames cocoindexWheels;
    };
  };

  cocoindex-code = python.pkgs.buildPythonApplication {
    pname = "cocoindex-code";
    version = cocoindexCodeVersion;
    pyproject = true;

    src = final.fetchurl {
      url = "https://files.pythonhosted.org/packages/c5/80/0aaa26997c5d6b54ef92e5b5480535e9ec84dbe2b0e42429201cd0cef5bf/cocoindex_code-${cocoindexCodeVersion}.tar.gz";
      sha256 = "ad871a0cb44e327f3fec4945d18530ffbde921056c56d9ccc2d4f1f68b0511d9";
    };

    build-system = with python.pkgs; [
      hatchling
      hatch-vcs
    ];

    # einops 0.8.1 in nixpkgs satisfies cocoindex-code's runtime use despite
    # the upstream >=0.8.2 pin; sqlite-vec ships with `0.0.0` in its wheel
    # METADATA so the >=0.1.0 check trips even though nixpkgs builds 0.1.6.
    pythonRelaxDeps = [
      "einops"
      "sqlite-vec"
    ];

    dependencies = [
      cocoindex
    ]
    ++ (with python.pkgs; [
      einops
      mcp
      msgspec
      numpy
      pathspec
      pydantic
      pyyaml
      questionary
      sqlite-vec
      typer
    ]);

    pythonImportsCheck = [ "cocoindex_code" ];

    meta = with final.lib; {
      description = "Semantic code search CLI built on cocoindex (slim — cloud embeddings via LiteLLM)";
      homepage = "https://github.com/cocoindex-io/cocoindex-code";
      license = licenses.asl20;
      mainProgram = "ccc";
    };
  };
in
{
  inherit cocoindex cocoindex-code;
}
