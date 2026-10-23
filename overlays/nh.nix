_final: prev: {
  nh-unwrapped =
    if prev.stdenv.hostPlatform.isDarwin then
      prev.nh-unwrapped.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./patches/nh-darwin-output-path.patch ];
      })
    else
      prev.nh-unwrapped;
}
