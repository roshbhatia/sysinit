final: _prev: {
  ask =
    let
      # The short name, installed rather than aliased: a shell alias is substituted before
      # the program runs, so `ask` would never see it and its own help would spell the name
      # the caller did not type. A second name on disk is also there for every shell, and
      # for a script, which an interactive alias is not.
      short = "_";
    in
    final.buildGoModule {
      pname = "ask";
      version = "0.1.0";

      src = ../pkgs/ask;

      # A hash, not null: ask draws its progress view with bubbletea, lipgloss, and bubbles.
      # Recompute it with `nix build` and copy the reported value on a dependency bump.
      vendorHash = "sha256-7Z/dVJWGXN3ZN5Me37gUbj67kE11vF6MfFJGIylTt8g=";

      nativeBuildInputs = [ final.installShellFiles ];

      # The completions come from cobra, so they are generated from the binary that was just
      # built rather than written by hand and left to drift. Each name generates its own,
      # from itself: a completion script names the command it completes, and ask reads that
      # name from the one it was called by.
      postInstall = ''
        ln -s ask "$out/bin/${short}"
      ''
      + final.lib.optionalString (final.stdenv.buildPlatform.canExecute final.stdenv.hostPlatform) ''
        for name in ask ${short}; do
          installShellCompletion --cmd "$name" \
            --bash <("$out/bin/$name" completion bash) \
            --zsh <("$out/bin/$name" completion zsh)
        done
      '';

      meta = {
        description = "Pipe something into a coding agent and print the answer, and only the answer";
        mainProgram = "ask";
        platforms = final.lib.platforms.unix;
      };
    };
}
