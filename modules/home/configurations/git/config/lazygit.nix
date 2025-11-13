{ lib, ... }:

let
  lazygitConfig = {
    gui = {
      mouseEvents = false;
      nerdFontsVersion = "3";
    };

    git = {
      scrollPastBottom = false;
      showCommandLog = false;
      showRandomTip = false;
    };

    customCommands = [
      {
        key = "a";
        context = "global";
        command = "gh copilot suggest -t git 'suggest a commit message based on the currently staged file in a simple conventional commit format'";
        description = "Suggest commit message";
        output = "popup";
        outputTitle = "AI Commit Suggestion";
        loadingText = "Suggesting commit message";
      }
    ];
  };

in
{
  xdg.configFile."lazygit/config.yml" = {
    text = lib.generators.toYAML {} lazygitConfig;
    force = true;
  };
}
