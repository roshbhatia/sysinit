# overlays/python-overrides.nix
# Purpose: tweak Python package overrides for compatibility.
{ ... }:

_final: prev: {
  # Fix setproctitle and accelerate test failures on macOS with Python 3.13
  # accelerate tests fail with Trace/BPT trap during pytest on darwin
  # aiohttp has flaky performance tests (test_regex_performance)
  # future-1.0.0 not yet marked as compatible with Python 3.13
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
