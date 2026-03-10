{ ... }:

_final: prev: {
  ast-grep = prev.ast-grep.overrideAttrs (oldAttrs: {
    # Skip tests on Darwin as they fail with "Illegal byte sequence (os error 92)"
    doCheck = !prev.stdenv.hostPlatform.isDarwin;
  });
}
