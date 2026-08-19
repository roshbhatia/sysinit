final: _prev: {
  seshy =
    let
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

      doCheck = true;

      nativeCheckInputs = [ final.git ];

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
