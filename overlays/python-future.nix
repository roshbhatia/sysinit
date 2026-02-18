{ ... }:

_final: prev: {
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      future = pythonPrev.future.overridePythonAttrs (_old: {
        disabled = false;
      });
    };
  };
}
