{ ... }:

final: _prev: {
  kubernetes-zeitgeist = final.buildGoModule rec {
    pname = "kubernetes-zeitgeist";
    version = "0.5.3";

    src = final.fetchFromGitHub {
      owner = "kubernetes-sigs";
      repo = "zeitgeist";
      rev = "v${version}";
      sha256 = "sha256-8vVqX6V0IMJk4GTksWEB88gwpG0Bp/LUI+LOcAQB1Gw=";
    };

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
