{ pkgs, ... }:
{
  home.packages = [
    (pkgs.runCommand "sysinit-shell-completions" { nativeBuildInputs = [ pkgs.installShellFiles ]; } ''
      ${pkgs.ere}/bin/ere completion bash > ere.bash
      ${pkgs.ere}/bin/ere completion zsh > _ere
      ${pkgs.ere}/bin/ere completion fish > ere.fish
      cp ${./worker.bash} worker.bash
      cp ${./worker.fish} worker.fish
      cp ${./sgg.fish} sgg.fish
      cp ${./worker.zsh} _worker
      cp ${./sgg.zsh} _sgg
      installShellCompletion --bash ere.bash worker.bash
      installShellCompletion --zsh _ere _worker _sgg
      installShellCompletion --fish ere.fish worker.fish sgg.fish
      mkdir -p "$out/share/nushell/vendor/autoload"
      cp ${./worker.nu} "$out/share/nushell/vendor/autoload/worker.nu"
    '')
  ];
}
