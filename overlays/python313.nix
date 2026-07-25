_final: prev: {
  # NOTE: setproctitle / accelerate / aiohttp / django test-disabling overrides
  # were removed — nixpkgs caches all four for both platforms at the pinned rev,
  # and overriding the python313 package set pinned the whole set (fsspec, etc.)
  # off-cache and forced local source builds. Only `future` remains: it is a
  # functional force-enable (upstream marks it disabled for py3.13), not a cache
  # knob, so it stays.
  python313 = prev.python313.override {
    packageOverrides = _pythonFinal: pythonPrev: {
      future = pythonPrev.future.overridePythonAttrs (_old: {
        disabled = false;
      });
    };
  };
}
