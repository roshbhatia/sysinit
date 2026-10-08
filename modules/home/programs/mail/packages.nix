{ pkgs }: ep: [
  (ep.trivialBuild {
    pname = "kitty-graphics";
    version = "1.4.0";
    src = pkgs.fetchFromGitHub {
      owner = "cashmeredev";
      repo = "kitty-graphics.el";
      rev = "13666d4eb2ef4eeed24697c0326368eff3667dce";
      hash = "sha256-3P4NQJpC0R1DRQ1oV1vbN1VD+Tb0wcMIvN1yA/pa/Rc=";
    };
  })
  ep.hydra
  ep.base16-theme
  ep.evil
  ep.vertico
  ep.orderless
  ep.marginalia
]
