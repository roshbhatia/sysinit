{ ... }:

_final: prev: {
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      setproctitle = pythonPrev.setproctitle.overridePythonAttrs (_old: {
        doCheck = false;
      });
      accelerate = pythonPrev.accelerate.overridePythonAttrs (_old: {
        doCheck = false;
      });
      aiohttp = pythonPrev.aiohttp.overridePythonAttrs (_old: {
        doCheck = false;
      });
      future = pythonPrev.future.overridePythonAttrs (_old: {
        disabled = false;
      });
    };
  };
}
