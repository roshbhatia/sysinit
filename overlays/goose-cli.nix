# overlays/goose-cli.nix
# Overlay for the block goose CLI tool only
# Usage: add this overlay to your overlays list in flake.nix or overlays/default.nix

_final: prev:

let
  # fetch the tokenizers at overlay-load time
  gpt-4o-tokenizer = prev.fetchurl {
    url = "https://huggingface.co/Xenova/gpt-4o/resolve/31376962e96831b948abe05d420160d0793a65a4/tokenizer.json";
    hash = "sha256-Q6OtRhimqTj4wmFBVOoQwxrVOmLVaDrgsOYTNXXO8H4=";
    meta.license = prev.lib.licenses.mit;
  };
  claude-tokenizer = prev.fetchurl {
    url = "https://huggingface.co/Xenova/claude-tokenizer/resolve/cae688821ea05490de49a6d3faa36468a4672fad/tokenizer.json";
    hash = "sha256-wkFzffJLTn98mvT9zuKaDKkD3LKIqLdTvDRqMJKRF2c=";
    meta.license = prev.lib.licenses.mit;
  };
in
{
  goose-cli = prev.rustPlatform.buildRustPackage (_finalAttrs: {
    pname = "goose-cli";
    version = "custom";

    src = prev.fetchFromGitHub {
      owner = "roshbhatia";
      repo = "goose";
      rev = "377ff91897db78b3a1b50e3ea4c063d8bd2ff9f4";
      hash = "sha256-nyDNC/fe5/S/+SYKbvQQbww8U8tXpyVZawmmplwa9DM=";
    };

    cargoHash = "sha256-FExQNSEe3rt/2vH19A3qlwwDBJNwZeoSJEAzQQ9K8zM=";

    nativeBuildInputs = [
      prev.pkg-config
      prev.protobuf
    ];

    buildInputs = [
      prev.dbus
    ]
    ++ prev.lib.optionals prev.stdenv.hostPlatform.isLinux [ prev.xorg.libxcb ];

    env.LIBCLANG_PATH = "${prev.lib.getLib prev.llvmPackages.libclang}/lib";

    preBuild = ''
      mkdir -p tokenizer_files/Xenova--gpt-4o tokenizer_files/Xenova--claude-tokenizer
      ln -s ${gpt-4o-tokenizer} tokenizer_files/Xenova--gpt-4o/tokenizer.json
      ln -s ${claude-tokenizer} tokenizer_files/Xenova--claude-tokenizer/tokenizer.json
    '';

    nativeCheckInputs = [ prev.writableTmpDirAsHomeHook ];

    __darwinAllowLocalNetworking = true;

    checkFlags = [
      "--no-run"
    ];

    passthru.updateScript = prev.nix-update-script { };

    meta = {
      description = "Goose CLI tool (roshbhatia fork)";
      homepage = "https://github.com/roshbhatia/goose";
      mainProgram = "goose";
      license = prev.lib.licenses.mit;
      platforms = prev.lib.platforms.linux ++ prev.lib.platforms.darwin;
    };
  });
}
