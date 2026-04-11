_:

final: prev: {
  direnv = prev.direnv.overrideAttrs (_old: {
    doCheck = false;
    env = (_old.env or { }) // {
      CGO_ENABLED = "1";
    };
  });
}
