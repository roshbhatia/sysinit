{ pkgs }:

{
  go = {
    bin = "${pkgs.go}/bin/go";
    env = ''
      export PATH="${pkgs.go}/bin:${pkgs.git}/bin:$PATH"
      export GOPATH="$HOME/go"
      export GOPROXY=https://proxy.golang.org,direct
      export GOSUMDB=sum.golang.org
      export GO111MODULE=on
      export PATH="$GOPATH/bin:$PATH"
      export CGO_ENABLED=1
      export CGO_LDFLAGS="-framework CoreFoundation -framework Security"
    '';
    installCmd = ''"$MANAGER_CMD" install -v "$pkg" || echo "Warning: Failed to install $pkg"'';
  };
}
