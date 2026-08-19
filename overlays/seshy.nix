final: _prev: {
  seshy =
    let
      # Read from cmd/root.go rather than duplicated here. `sy --version`
      # prints that const, so a second copy in this file could only ever drift,
      # and the drift would be invisible: it would show up in the store path and
      # nowhere a user looks.
      version =
        let
          root = builtins.readFile ../pkgs/seshy/cmd/root.go;
          matched = builtins.match ''.*const version = "([0-9]+\.[0-9]+\.[0-9]+)".*'' root;
        in
        if matched == null then
          throw "overlays/seshy.nix: could not read `const version` from pkgs/seshy/cmd/root.go. If the declaration moved, update this matcher rather than hardcoding a version."
        else
          builtins.head matched;
    in
    final.buildGoModule {
      pname = "seshy";
      inherit version;

      src = ../pkgs/seshy;

      vendorHash = "sha256-6B9O6ho4COpJy4HlkzQ0lk+ieezRO3xg9LyLHzoxYzc=";

      # No `subPackages`. It scopes the check phase as well as the build, so
      # restricting it to "." made `go test` run against the root package only,
      # which has no test files: the build reported a passing test phase while
      # testing nothing.
      doCheck = true;

      # The unit tests shell out to `git` to build worktree fixtures. Without it
      # on PATH inside the sandbox every delete test fails with "executable file
      # not found".
      nativeCheckInputs = [ final.git ];

      # buildGoModule names the output after the module's last path segment,
      # which is `seshy`. Every caller invokes `sy`.
      postInstall = ''
        mv "$out/bin/seshy" "$out/bin/sy"
        ln -s "$out/bin/sy" "$out/bin/seshy"
      '';

      meta = {
        description = "Minimal session manager for multi-repo, worktree-based work";
        mainProgram = "sy";
        platforms = final.lib.platforms.unix;
      };
    };
}
