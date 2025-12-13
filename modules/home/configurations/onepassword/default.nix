{
  lib,
  osConfig ? { },
  pkgs,
  ...
}:

let
  isMacOS = osConfig.system or null == null;
in
{
  # 1Password CLI is available on macOS
  home.packages = lib.optionals isMacOS (
    with pkgs;
    [
      _1password
    ]
  );

  # Initialize 1Password shell plugins on macOS
  programs.bash.initExtra = lib.mkIf isMacOS ''
    eval "$(op shell-plugins init --shell bash)" 2>/dev/null || true
  '';

  programs.zsh.initExtra = lib.mkIf isMacOS ''
    eval "$(op shell-plugins init --shell zsh)" 2>/dev/null || true
  '';
}
