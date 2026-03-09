{ ... }:

final: _prev:
let
  sources = final.nvfetcherSources.kubernetes-zeitgeist;
  version = final.lib.removePrefix "v" sources.version;
in
{
  kubernetes-zeitgeist = final.buildGoModule {
    pname = "kubernetes-zeitgeist";
    inherit version;

    inherit (sources) src;

    vendorHash = "sha256-E7ntN/BqDzgj9nJ7rKMDq8EBOvbvKQxQRI3/4mvkHQM=";

    subPackages = [ "." ];

    ldflags = [
      "-s"
      "-w"
      "-X=sigs.k8s.io/zeitgeist/pkg/version.version=${version}"
    ];

    meta = with final.lib; {
      description = "Language-agnostic dependency checker for Kubernetes projects";
      homepage = "https://github.com/kubernetes-sigs/zeitgeist";
      license = licenses.asl20;
      maintainers = [ ];
      mainProgram = "zeitgeist";
    };
  };
}
