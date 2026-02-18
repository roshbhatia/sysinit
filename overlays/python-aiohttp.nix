{ ... }:

_final: prev: {
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      aiohttp = pythonPrev.aiohttp.overridePythonAttrs (_old: {
        doCheck = false;
      });
    };
  };
}
