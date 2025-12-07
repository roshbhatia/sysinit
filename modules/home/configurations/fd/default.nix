{
  config,
  lib,
  ...
}:
with lib;
{
  config = {
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
