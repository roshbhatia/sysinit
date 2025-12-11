{
  lib,
  ...
}:

let

  lazygitConfig = {
    gui = {
      mouseEvents = false;
      nerdFontsVersion = "3";

      theme = {
        # Clear visual distinction for staged vs unstaged
        unstagedChangesColor = [
          "red"
        ];

        activeBorderColor = [
          "cyan"
          "bold"
        ];

        inactiveBorderColor = [
          "white"
        ];

        # Cherry-picked commits
        cherryPickedCommitFgColor = [
          "blue"
        ];

        cherryPickedCommitBgColor = [
          "cyan"
        ];

        # Marked base commit
        markedBaseCommitFgColor = [
          "blue"
        ];

        markedBaseCommitBgColor = [
          "yellow"
        ];

        # Default colors
        defaultFgColor = [
          "default"
        ];

        # Search border
        searchingActiveBorderColor = [
          "cyan"
          "bold"
        ];

        # Options text
        optionsTextColor = [
          "blue"
        ];
      };
    };

    git = {
      scrollPastBottom = false;
      showCommandLog = false;
      showRandomTip = false;
    };

    customCommands = [ ];
  };

in
{
  xdg.configFile."lazygit/config.yml" = {
    text = lib.generators.toYAML { } lazygitConfig;
    force = true;
  };
}
