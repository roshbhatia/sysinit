final: _prev:
let
  inherit (final) lib stdenv;

  version = "0.2.2";
  base = "https://github.com/perplexityai/perplexity-cli/releases/download/v${version}";

  platformInfo = {
    "aarch64-darwin" = {
      asset = "pplx-aarch64-apple-darwin.bin";
      hash = "sha256-6XZHj8/sUfNvWw8o1kd+oEIyMpQoTgawKi6bGzOcF3M=";
    };
    "aarch64-linux" = {
      asset = "pplx-aarch64-linux-gnu.bin";
      hash = "sha256-NfjfUxS2TupXONNuhTG4DgKeyvno3h1jF+XzsPZknqQ=";
    };
    "x86_64-linux" = {
      asset = "pplx-x86_64-linux-gnu.bin";
      hash = "sha256-F+SP9yiuqaS5dptqCEQnq6lejhikPEvJxYR9BUw4tME=";
    };
  };

  info =
    platformInfo.${stdenv.hostPlatform.system}
      or (throw "pplx: unsupported platform ${stdenv.hostPlatform.system}");
in
{
  pplx = stdenv.mkDerivation {
    pname = "pplx";
    inherit version;

    src = final.fetchurl {
      url = "${base}/${info.asset}";
      inherit (info) hash;
    };

    dontUnpack = true;

    nativeBuildInputs = lib.optionals stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];
    buildInputs = lib.optionals stdenv.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

    installPhase = ''
      runHook preInstall
      install -Dm755 $src $out/bin/pplx
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Perplexity CLI for live web search and page-content fetch";
      homepage = "https://github.com/perplexityai/perplexity-cli";
      license = licenses.mit;
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "pplx";
    };
  };
}
