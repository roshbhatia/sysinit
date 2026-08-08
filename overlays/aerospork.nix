final: _prev:
let
  inherit (final.nvfetcherSources.aerospork) version src;
in
{
  # aerospork — a fork of nikitabobko/AeroSpace, taken up after an upstream PR for
  # DisplayLink monitor support was closed unreviewed. It matches monitors by
  # hardware UUID and EDID, not just by display name, which is what this repo's
  # per-monitor gaps need to survive a dock cycle between two identical panels.
  #
  # Not in nixpkgs. The release archive has the same layout as AeroSpace's, so this
  # is the nixpkgs aerospace expression with the names changed; the only structural
  # difference is the extra `aerospork-v$ver/` root the default unpackPhase strips.
  #
  # Deliberately NOT an override of pkgs.aerospace: the nix-darwin
  # services.aerospace module hardcodes
  # `${package}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace`, so faking that
  # path would mean adding a symlink inside a notarized bundle and breaking its
  # code signature seal. modules/darwin/aerospork.nix drives launchd directly instead.
  aerospork = final.stdenvNoCC.mkDerivation {
    pname = "aerospork";
    inherit version src;

    nativeBuildInputs = [
      final.unzip
      final.installShellFiles
    ];

    # bin/aerospork ships as a relative symlink to a SIBLING AeroSpork.app, so
    # copying it verbatim next to an app that moved under Applications/ leaves it
    # dangling. Relink by absolute path instead; the CLI and the server are one
    # signed bundle, so it has to keep pointing inside it.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/Applications $out/bin
      mv AeroSpork.app $out/Applications
      ln -s $out/Applications/AeroSpork.app/Contents/MacOS/aerospork-cli $out/bin/aerospork
      runHook postInstall
    '';

    postInstall = ''
      installManPage manpage/*
      installShellCompletion --bash shell-completion/bash/aerospork
      installShellCompletion --fish shell-completion/fish/aerospork.fish
      installShellCompletion --zsh  shell-completion/zsh/_aerospork
    '';

    # The bundle is notarized and hardened. Stripping rewrites the Mach-O and
    # invalidates the signature, which the kernel refuses to load on arm64.
    dontFixup = true;

    meta = with final.lib; {
      description = "i3-like tiling window manager for macOS, fork of AeroSpace";
      homepage = "https://github.com/wbsmolen/aerospork";
      license = licenses.mit;
      mainProgram = "aerospork";
      platforms = platforms.darwin;
      sourceProvenance = [ sourceTypes.binaryNativeCode ];
    };
  };
}
