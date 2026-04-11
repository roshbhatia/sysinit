_:

final: _prev: {
  nvfetcherSources = import ../_sources/generated.nix {
    inherit (final)
      fetchurl
      fetchgit
      fetchFromGitHub
      dockerTools
      ;
  };
}
