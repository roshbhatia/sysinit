_:

{
  home.shellAliases.fda = "fd --no-ignore";
  programs.fd = {
    enable = true;
    hidden = true;

    extraOptions = [
      "--follow"
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
}
