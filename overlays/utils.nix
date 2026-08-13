final: _prev: {
  utils = final.buildGoModule {
    pname = "utils";
    version = "0.1.0";

    src = ../pkgs/utils;

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
      mainProgram = "utils";
      platforms = final.lib.platforms.unix;
    };
  };
}
