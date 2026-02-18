{ ... }:

_final: prev: {
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
    };
  };

  python311 = prev.python311.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
    };
  };
}
