final: _prev: {
  sysinit-agent = final.buildGoModule {
    pname = "sysinit-agent";
    version = "0.1.0";

    src = ../pkgs/sysinit-agent;

    vendorHash = "sha256-/Bl4G5STa5lnNntZnMmt+BfES+N7ZYAwC9tzpuqUKcc=";

    # The tests build real working trees: the store path is derived from
    # `rev-parse --show-toplevel`, so a fake directory would key every test on
    # the same file. HOME is set because git refuses to run without one.
    nativeCheckInputs = [ final.git ];
    preCheck = ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
    '';

    meta = {
      description = "Agent runtime commands that used to be shell scripts";
      mainProgram = "sysinit-agent";
      platforms = final.lib.platforms.unix;
    };
  };
}
