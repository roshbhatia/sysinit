final: _prev: {
  specutil = final.buildGoModule {
    pname = "specutil";
    version = "0.1.0";

    src = ../pkgs/specutil;

    vendorHash = "sha256-p3W9SBXEWTL7rWpW95cOoNJ9CArJlAsi3Vfy/m1d2z0=";

    nativeCheckInputs = [ final.git ];
    preCheck = ''
      export HOME="$TMPDIR/home"
      mkdir -p "$HOME"
      git config --global user.email nix@localhost
      git config --global user.name nix
    '';

    meta = {
      description = "Project spec-framework change artifacts into other artifacts and visualizations";
      mainProgram = "specutil";
      platforms = final.lib.platforms.unix;
    };
  };
}
