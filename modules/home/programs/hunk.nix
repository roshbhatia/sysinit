{
  inputs,
  ...
}:

{
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  programs.hunk = {
    enable = true;
    enableGitIntegration = true;
    settings = {
      # "auto" queries the terminal background and selects a light or dark
      # github theme, with a dark fallback.
      theme = "auto";
    };
  };
}
