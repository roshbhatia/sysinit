{
  ...
}:

final: prev:
let
  # Pin to latest main branch commit (bleeding edge)
  version = "unstable-2025-10-09";
  rev = "4cc5777b630ba4d6a9c964248531f283178a4717";
  sha256 = "sha256-CF4xDoRYey9F8/XSW/euNb8IjZXyP6k0Nj61shsmyEo=";
in
{
  weechatScripts = prev.weechatScripts // {
    weechat-matrix-rs = final.rustPlatform.buildRustPackage {
      pname = "weechat-matrix-rs";
      inherit version;

      src = final.fetchFromGitHub {
        owner = "poljar";
        repo = "weechat-matrix-rs";
        inherit rev sha256;
      };

      cargoHash = "sha256-jAlBCmLJfWWAUHd3ySB930iqAVXMh6ueba7xS///Rt0=";

      nativeBuildInputs = with final; [
        pkg-config
      ];

      buildInputs = with final; [
        openssl
        sqlite
        weechat
      ];

      passthru = {
        scripts = [ "matrix.so" ];
      };

      postInstall = ''
        mkdir -p $out/share
        ln -s $out/lib/libmatrix${final.stdenv.hostPlatform.extensions.sharedLibrary} $out/share/matrix.so
      '';

      meta = with final.lib; {
        description = "Matrix protocol client for WeeChat written in Rust";
        homepage = "https://github.com/poljar/weechat-matrix-rs";
        license = licenses.isc;
        maintainers = [ ];
        platforms = platforms.unix;
      };
    };
  };
}
