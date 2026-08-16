final: _prev: {
  ask =
    let
      # pkgs/ask/wrappers.txt is the one list of the names the binary answers
      # to; pkgs/ask/main.go dispatches on the same names.
      wrappers = final.lib.filter (name: name != "") (
        final.lib.splitString "\n" (builtins.readFile ../pkgs/ask/wrappers.txt)
      );
    in
    final.buildGoModule {
      pname = "ask";
      version = "0.1.0";

      src = ../pkgs/ask;

      vendorHash = "sha256-GTJxlZNc+yfQN9RncGWfAKfoSmVasKgyS6ycCy7nDZU=";

      # pkgs/ask/wrappers_test.go asserts that wrappers.txt still matches the
      # provider registry the binary dispatches on, so the build is what catches
      # a provider added without its `_xxx` symlink. The tests take under a
      # second.
      doCheck = true;

      nativeBuildInputs = [ final.installShellFiles ];

      postInstall = ''
        for name in ${final.lib.escapeShellArgs wrappers}; do
          ln -s ask "$out/bin/$name"
        done
      ''
      + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
        for name in ask ${final.lib.escapeShellArgs wrappers}; do
          installShellCompletion --cmd "$name" \
            --bash <("$out/bin/$name" completion bash) \
            --zsh <("$out/bin/$name" completion zsh)
        done
      '';

      meta = {
        description = "Agents in your shell!";
        mainProgram = "ask";
        platforms = final.lib.platforms.unix;
      };
    };
}
