final: _prev: {
  ask =
    let
      short = "_";
    in
    final.buildGoModule {
      pname = "ask";
      version = "0.1.0";

      src = ../pkgs/ask;

      vendorHash = "sha256-7Z/dVJWGXN3ZN5Me37gUbj67kE11vF6MfFJGIylTt8g=";

      nativeBuildInputs = [ final.installShellFiles ];

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
        description = "Agents in your shell!";
        mainProgram = "ask";
        platforms = final.lib.platforms.unix;
      };
    };
}
