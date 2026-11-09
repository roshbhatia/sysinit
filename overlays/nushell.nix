_final: prev: {
  nushell =
    if prev.lib.versionAtLeast prev.nushell.version "0.117.0" then
      prev.nushell
    else
      prev.nushell.overrideAttrs (
        finalAttrs: _old: {
          version = "0.116.2";
          src = prev.fetchFromGitHub {
            owner = "nushell";
            repo = "nushell";
            rev = "09f275bd004a2d7113952327beeca19a1da2a3d9";
            hash = "sha256-isRdZr5aRXfKZtvie2vOPTJyx1k8AHLs0HiqZvc4gjQ=";
          };
          # This revision includes @structured and the stable package's TLS fixes.
          patches = [ ];
          cargoHash = "sha256-IwfwFg0Hwid3lMapzWP6ENwt5WrUHeZZffpvfTOMGbU=";
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = finalAttrs.cargoHash;
          };
        }
      );
}
