{
  user = {
    username = "rshnbhatia";
    hostname = "lv426";
  };

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
  };

  darwin = {
    homebrew = {
      additionalPackages = {
        taps = [
          "qmk/qmk"
        ];
        brews = [
          "qmk"
        ];
        casks = [
          "betterdiscord-installer"
          "calibre"
          "discord"
          "notion"
          "notion-calendar"
          "notion-mail"
          "orbstack"
          "steam"
        ];
      };
    };
  };

  llm = {
    agentsMd = {
      enabled = true;
      autoUpdate = true;
    };

    execution = {
      nixShell = {
        enabled = true;
        autoDeps = true;
        sandbox = true;
      };

      terminal = {
        wezterm = {
          enabled = true;
          newWindow = true;
          monitor = true;
        };
      };

      isolation = {
        enabled = true;
        monitoring = true;
        timeout = 300;
      };
    };

    claude = {
      enabled = true;
      mcp = {
        aws = {
          region = "us-east-1";
          enabled = true;
        };
        additionalServers = { };
      };
    };

    goose = {
      enabled = true;
      provider = "github_copilot";
      leadModel = null;
      model = "gpt-4o-mini";
      alphaFeatures = true;
      mode = "smart_approve";
    };

    opencode = {
      enabled = true;
      theme = "auto";
      autoupdate = true;
      share = "disabled";
    };

    cursor = {
      enabled = true;
      permissions = {
        shell = {
          allowed = [
            "ls"
            "rg"
            "head"
            "git"
            "wc"
            "grep"
            "cd"
            "make"
            "pwd"
            "mkdir"
            "cat"
            "which"
            "tail"
          ];
        };

        kubectl = {
          allowed = [
            "get"
            "describe"
            "logs"
            "explain"
            "api-resources"
            "api-versions"
            "cluster-info"
            "version"
            "config"
            "top"
          ];
        };
      };

      vimMode = true;
    };

    mcp = {
      servers = { };
      additionalServers = [ ];
    };
  };
}
