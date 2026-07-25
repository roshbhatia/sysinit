_final: prev: {
  # open-policy-agent's darwin build is not on cache.nixos.org and its check
  # phase fails in the sandbox, so skip tests there. On Linux the pristine build
  # is cached — leave it untouched for a cache hit.
  open-policy-agent =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.open-policy-agent.overrideAttrs (_old: {
        doCheck = false;
      })
    else
      prev.open-policy-agent;
}
