final: _prev: {
  # Upstream tags are `mise-nix@<version>`, so the pin is the commit that tag
  # points at. Bump the rev and the hash together.
  mise-nix = final.stdenvNoCC.mkDerivation {
    pname = "mise-nix";
    version = "0.21.0";

    src = final.fetchFromGitHub {
      owner = "jbadeau";
      repo = "mise-nix";
      rev = "e310c4c20e8273ba850298c10fbe97d0c858c300";
      hash = "sha256-4aNEmor6DZfw8MkT6tTPT9nYUvkeXwgLisNjRkDqSyY=";
    };

    # Upstream builds with `--no-link`, so a GC deletes a tool mise still lists,
    # and it reports an unreachable search.devbox.sh as "package not found".
    patches = [
      ./patches/mise-nix-gc-root.patch
      ./patches/mise-nix-loud-nixhub-failure.patch
    ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r hooks lib metadata.lua "$out/"
      runHook postInstall
    '';

    meta = with final.lib; {
      description = "mise backend plugin that installs tools from nixpkgs";
      homepage = "https://github.com/jbadeau/mise-nix";
      license = licenses.asl20;
      platforms = platforms.unix;
    };
  };
}
