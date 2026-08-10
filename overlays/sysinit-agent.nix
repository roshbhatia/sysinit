final: _prev: {
  sysinit-agent = final.buildGoModule {
    pname = "sysinit-agent";
    version = "0.1.0";

    src = ../pkgs/sysinit-agent;

    # null, not a hash.
    vendorHash = null;

    # The tests build real working trees: the store path is derived from
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
