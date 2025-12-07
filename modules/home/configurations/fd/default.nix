{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.programs.fd;
in
{
  config = mkIf cfg.enable {
    programs.fd = {
      hidden = true;
      extraOptions = [
        "--follow"
        "--no-ignore-vcs"
      ];
      ignores = [
        ".git/"
        "node_modules/"
        ".direnv/"
        ".devenv/"
        "target/"
        "dist/"
        "build/"
        ".DS_Store"
        "*.pyc"
        "__pycache__/"
        ".venv/"
        ".env/"
      ];
    };
  };
}
