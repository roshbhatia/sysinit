final: prev:

let
  helixSteelRev = "5a8635beda77414850a2b9604aa0643e4713db3b";
  helixSteelSrc = final.fetchFromGitHub {
    owner = "mattwparas";
    repo = "helix";
    rev = helixSteelRev;
    hash = "sha256-7mUAINEKnPPCHqiXT+zU5bve4dqcggdjBuHRInhTGEY=";
  };
  helix-unwrapped = prev.helix-unwrapped.overrideAttrs {
    src = helixSteelSrc;
    cargoDeps = final.rustPlatform.fetchCargoVendor {
      src = helixSteelSrc;
      hash = "sha256-OrL4KNvGCg2uxpzZZWBKywfLjKrfLqGzF0yzsFwM9Po=";
    };
    patches = [ ];
  };
in
{
  inherit helix-unwrapped;
  helix = prev.helix.override { inherit helix-unwrapped; };
}
