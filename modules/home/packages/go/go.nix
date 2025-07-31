{
  lib,
  values,
  utils,
  ...
}:

let
  goPackages = [
    "golang.org/x/tools/cmd/goimports@latest"
    "golang.org/x/tools/cmd/gonew@latest"
    "golang.org/x/vuln/cmd/govulncheck@latest"
    "gotest.tools/gotestsum@latest"
    "go.uber.org/mock/mockgen@latest"
    "github.com/abenz1267/gomvp@latest"
    "github.com/abice/go-enum@latest"
    "github.com/davidrjenni/reftools/cmd/fillswitch@latest"
    "github.com/davidrjenni/reftools/cmd/fillstruct@latest"
    "github.com/davidrjenni/reftools/cmd/fixplurals@latest"
    "github.com/golangci/golangci-lint/cmd/golangci-lint@v1.64.8"
    "github.com/kyoh86/richgo@latest"
    "github.com/onsi/ginkgo/v2/ginkgo@latest"
    "github.com/tmc/json-to-struct@latest"
    "github.com/twpayne/go-jsonstruct/v3/cmd/gojsonstruct@latest"
    "mvdan.cc/gofumpt@latest"
  ]
  ++ (values.go.additionalPackages or [ ]);
in
{
  home.activation.goPackages = utils.sysinit.mkPackageManagerActivation "go" goPackages;
}
