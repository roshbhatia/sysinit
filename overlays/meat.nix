{
  inputs,
  ...
}:

final: _prev: {
  meat = final.buildGoModule {
    pname = "meat";
    version = "0-unstable-2026-08-02";

    src = inputs.meat;

    vendorHash = null;

    subPackages = [ "cmd/meat" ];

    doCheck = false;

    meta = with final.lib; {
      description = "Abridge a code diff into a reading diff";
      homepage = "https://github.com/boldsoftware/meat";
      license = licenses.unfree;
      mainProgram = "meat";
      platforms = platforms.unix;
    };
  };
}
