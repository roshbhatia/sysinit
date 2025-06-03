{
  lib,
  overlay,
  ...
}:

let
  activation = import ../../../lib/activation { inherit lib; };
in
{
  home.activation.goPackages = activation.mkPackageManager {
    name = "go";
    basePackages = [
      "golang.org/x/tools/cmd/goimports@latest"
      "github.com/davidrjenni/reftools/cmd/fillswitch@latest"
      "github.com/davidrjenni/reftools/cmd/fillstruct@latest"
      "github.com/davidrjenni/reftools/cmd/fixplurals@latest"
    ];
    additionalPackages = (overlay.go.additionalPackages or [ ]);
    executableArguments = [ "install" ];
    executableName = "go";
  };
}

