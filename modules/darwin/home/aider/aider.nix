{ config, lib, pkgs, ... }:

{
  home.file.".aider.conf.yml" = {
    source = ./aider.conf.yml;
    force = true;
  };

  home.file.".aider.nvim.copilot.conf.yml" = {
    source = ./aider.nvim.copilot.conf.yml;
    force = true;
  };

  home.file.".aider.nvim.copilot.model.settings.yml" = {
    source = ./aider.nvim.copilot.model.settings.yml;
    force = true;
  };

  home.file.".local/bin/get-copilot-token" = {
    source = ./get-copilot-token.sh;
    force = true;
  };
}
