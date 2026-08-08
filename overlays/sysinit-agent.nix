final: _prev: {
  sysinit-agent = final.buildGoModule {
    pname = "sysinit-agent";
    version = "0.1.0";

    src = ../pkgs/sysinit-agent;

    vendorHash = null;

    meta = {
      description = "Agent runtime commands that used to be shell scripts";
      mainProgram = "sysinit-agent";
      platforms = final.lib.platforms.unix;
    };
  };
}
