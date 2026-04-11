_:

_final: prev: {
  open-policy-agent = prev.open-policy-agent.overrideAttrs (_old: {
    doCheck = false;
  });
}
