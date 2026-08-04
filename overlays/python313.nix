_final: prev: {
  # upstream disables `future` on Python 3.13
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      future = pythonPrev.future.overridePythonAttrs (_old: {
        disabled = false;
      });
    };
  };
}
