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
      hash = "sha256-FExQNSEe3rt/2vH19A3qlwwDBJNwZeoSJEAzQQ9K8zM=";
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
      # need dbus-daemon
      "--skip=config::base::tests::test_multiple_secrets"
      "--skip=config::base::tests::test_secret_management"
      "--skip=config::base::tests::test_concurrent_extension_writes"
      # Observer should be Some with both init project keys set
      "--skip=tracing::langfuse_layer::tests::test_create_langfuse_observer"
      "--skip=providers::gcpauth::tests::test_token_refresh_race_condition"
      # Lazy instance has previously been poisoned
      "--skip=jetbrains::tests::test_capabilities"
      "--skip=jetbrains::tests::test_router_creation"
      "--skip=logging::tests::test_log_file_name::with_session_name_and_error_capture"
      "--skip=logging::tests::test_log_file_name::with_session_name_without_error_capture"
      "--skip=logging::tests::test_log_file_name::without_session_name"
      "--skip=developer::tests::test_text_editor_str_replace"
      # need API keys
      "--skip=providers::factory::tests::test_create_lead_worker_provider"
      "--skip=providers::factory::tests::test_create_regular_provider_without_lead_config"
      "--skip=providers::factory::tests::test_lead_model_env_vars_with_defaults"
    ]
    ++ prev.lib.optionals prev.stdenv.hostPlatform.isDarwin [
      "--skip=providers::gcpauth::tests::test_load_from_metadata_server"
      "--skip=providers::oauth::tests::test_get_workspace_endpoints"
      "--skip=tracing::langfuse_layer::tests::test_batch_manager_spawn_sender"
      "--skip=tracing::langfuse_layer::tests::test_batch_send_partial_failure"
      "--skip=tracing::langfuse_layer::tests::test_batch_send_success"
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

