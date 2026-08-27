final: prev:

let
  helixSteelRev = "5a8635beda77414850a2b9604aa0643e4713db3b";
  helixSteelSrc = final.fetchFromGitHub {
    owner = "mattwparas";
    repo = "helix";
    rev = helixSteelRev;
    hash = "sha256-7mUAINEKnPPCHqiXT+zU5bve4dqcggdjBuHRInhTGEY=";
  };
  helixFileWatcherSrc = final.fetchFromGitHub {
    owner = "mtul0729";
    repo = "helix-file-watcher";
    rev = "2f7bb7ea3c505009d88ae23c31e6965f7165ddd1";
    hash = "sha256-oSNcUCpbRpmXYgmtY2jKAJn34Bqogj7jWQe0lxaGaek=";
  };
  helix-unwrapped = prev.helix-unwrapped.overrideAttrs {
    src = helixSteelSrc;
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      src = helixSteelSrc;
      hash = "sha256-OrL4KNvGCg2uxpzZZWBKywfLjKrfLqGzF0yzsFwM9Po=";
    };
    patches = [ ];
  };
in
{
  inherit helix-unwrapped;
  helix = prev.helix.override { inherit helix-unwrapped; };
  helix-file-watcher = final.rustPlatform.buildRustPackage {
    pname = "helix-file-watcher";
    version = "0.1.0";
    src = helixFileWatcherSrc;
    cargoHash = "sha256-BJ+YqAXDsiADmwUC1Ohioa5f7PTH14/RoamN+5RWT9M=";
    postPatch = ''
      substituteInPlace file-watcher.scm \
        --replace-fail \
          '(lambda (doc-id) (equal? (editor-document->path doc-id) path))' \
          '(lambda (doc-id)
             (define doc-path (editor-document->path doc-id))
             (and doc-path (equal? (try-canonicalize-path doc-path) path)))'
    '';
    installPhase = ''
      runHook preInstall
      install -Dm755 target/${final.stdenv.hostPlatform.rust.rustcTargetSpec}/release/libhelix_file_watcher${final.stdenv.hostPlatform.extensions.sharedLibrary} \
        $out/lib/libhelix_file_watcher${final.stdenv.hostPlatform.extensions.sharedLibrary}
      ${final.lib.optionalString final.stdenv.hostPlatform.isDarwin ''
        install_name_tool -id $out/lib/libhelix_file_watcher${final.stdenv.hostPlatform.extensions.sharedLibrary} \
          $out/lib/libhelix_file_watcher${final.stdenv.hostPlatform.extensions.sharedLibrary}
      ''}
      install -Dm644 {cog,file-watcher,helix-file-watcher}.scm -t $out/share/steel/cogs/helix-file-watcher
      runHook postInstall
    '';
    meta = {
      description = "Helix Steel plugin for reloading files changed on disk";
      homepage = "https://github.com/mtul0729/helix-file-watcher";
      license = final.lib.licenses.mit;
      platforms = final.lib.platforms.unix;
    };
  };
}
