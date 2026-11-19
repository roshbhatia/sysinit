final: prev:
let
  version = "0.1.2";
  inherit (final.stdenv.hostPlatform) isDarwin isLinux;

  src = final.fetchFromGitHub {
    owner = "vercel-labs";
    repo = "screen-relay";
    tag = "v${version}";
    hash = "sha256-oiMQG3xISh6pO3mOkBxMhWA+o/rNua/Q11wdjoisKl4=";
  };

  # Programs the CLI starts for a Linux X11 session with an XFCE desktop.
  linuxSessionPrograms = [
    final.util-linux
    final.xorg-server
    final.xauth
    final.xprop
    final.xwininfo
    final.xdpyinfo
    final.setxkbmap
    final.xfce4-session
    final.dbus
  ];
in
{
  screen-relay = prev.buildNpmPackage {
    pname = "screen-relay";
    inherit version src;

    npmDepsHash = "sha256-M3jwyBAfqFn6V9aiKkegeZJkbxcznX/0swUO8EtI1mQ=";

    nativeBuildInputs = [
      final.pkg-config
      final.makeWrapper
    ];

    buildInputs = [
      final.x264
      final.libwebsockets
      final.zlib
    ]
    ++ final.lib.optionals isDarwin [ final.openssl ]
    ++ final.lib.optionals isLinux [
      final.libx11
      final.libxext
      final.libxdamage
      final.libxfixes
      final.libxtst
    ];

    postBuild = ''
      make relay-engine BACKENDS=${if isDarwin then "macos" else "x11"}
    '';

    # The CLI searches beside itself before PATH, so the engine stays out of the
    # CLI directory; on macOS the signed copy on PATH must win.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/lib/screen-relay $out/bin
      cp -r dist skills package.json THIRD-PARTY-NOTICES.md $out/lib/screen-relay/
      install -Dm755 relay-engine $out/libexec/screen-relay/relay-engine
      makeWrapper ${final.lib.getExe final.nodejs_22} $out/bin/screen-relay \
        --add-flags $out/lib/screen-relay/dist/cli/relay.mjs \
        ${final.lib.optionalString isLinux "--prefix PATH : ${
          final.lib.makeBinPath ([ (placeholder "out") ] ++ linuxSessionPrograms)
        }"}
      ${final.lib.optionalString isLinux "ln -s $out/libexec/screen-relay/relay-engine $out/bin/relay-engine"}
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "Desktop streaming and control for people and AI agents";
      homepage = "https://github.com/vercel-labs/screen-relay";
      license = licenses.asl20;
      platforms = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-linux"
      ];
      mainProgram = "screen-relay";
    };
  };
}
