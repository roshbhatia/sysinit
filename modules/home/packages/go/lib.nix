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
    installCmd = ''"$MANAGER_CMD" install "$pkg" 2>/dev/null || echo "Warning: Failed to install $pkg"'';
    cleanupCmd = ''
      comm -23 <(ls "$HOME/go/bin" 2>/dev/null | sort) <(sort "$managed_pkg_file") | while read bin; do
        rm -f "$HOME/go/bin/$bin"
      done
    '';
  };
}
