{ ... }:

{
  home.file.".aider.conf.yml" = {
    source = ./aider.conf.yml;
    force = true;
  };

  home.file.".aider.nvim.copilot.conf.yml" = {
    source = ./aider.nvim.copilot.conf.yml;
    force = true;
  };
}

