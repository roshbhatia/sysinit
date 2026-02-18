{ ... }:

_final: prev: {
  python311 = prev.python311.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      setproctitle = pythonPrev.setproctitle.overridePythonAttrs (_old: {
        doCheck = false;
      });
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
    };
  };
}
