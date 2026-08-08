_final: prev: {
  open-policy-agent =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.open-policy-agent.overrideAttrs (_old: {
        doCheck = false;
      })
    else
      prev.open-policy-agent;
}
