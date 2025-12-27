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
      local gopath=$("$MANAGER_CMD" env GOPATH)

      local installed=$(
        /bin/ls -l "$gopath/bin" 2>/dev/null \
          | tail -n +2 \
          | awk '{print $9}' \
          | grep -v "^$" \
          | sort
      )

      local managed=$(sort "$managed_pkg_file")

      comm -23 <(echo "$installed") <(echo "$managed") | while read pkg; do
        [ -n "$pkg" ] && rm -f "$gopath/bin/$pkg" 2>/dev/null || true
      done
    '';
  };
}
