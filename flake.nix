{
  description = "Personal system configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    systems.url = "github:nix-systems/default";

    darwin = {
      url = "github:nix-darwin/nix-darwin/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";

    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    elephant-goldfish-model = {
      url = "github:google/elephant-goldfish-model";
      flake = false;
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:danth/stylix/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    onepassword-shell-plugins = {
      url = "github:1Password/shell-plugins";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-gaming = {
      url = "github:fufexan/nix-gaming";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    swayfx = {
      url = "github:WillPower3309/swayfx";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    cupcake = {
      url = "github:eqtylab/cupcake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-claude-code = {
      url = "github:ryoppippi/nix-claude-code";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ask = {
      url = "github:roshbhatia/ask/cb859b1eb08f253e916106fda4fa92a68a941d75";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    gate = {
      url = "github:roshbhatia/gate/v0.5.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    changes = {
      url = "github:roshbhatia/changes";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    seshy = {
      url = "github:roshbhatia/seshy/06c90a3653d1bd2908be90b12fadf0a4f21fe329";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    ere = {
      url = "github:roshbhatia/ere/44814e2cad9bd719c03435d9a5e6d916b1c5cb97";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    traces = {
      url = "github:roshbhatia/traces/8b24aada5697dd6a6d68b6328fc63ef127eb5589";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    agent-signals = {
      url = "github:roshbhatia/agent-signals";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-tabs = {
      url = "github:roshbhatia/firefox-tabs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    worker = {
      url = "github:roshbhatia/worker";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    command-palette = {
      url = "github:roshbhatia/CommandPalette.spoon";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agent-notes = {
      url = "github:roshbhatia/agent-notes";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Keep the fork's dependency lock so consumers match its CI cache paths.
    wezterm-fork.url = "github:roshbhatia/wezterm/079924208f14f19b15831a9cb75650af455b5a59?dir=nix";
    sysinit-wezterm = {
      url = "github:roshbhatia/sysinit.wezterm/b480c2b0618c41b8d9ffdf10a008dee83bd7cf9b";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    sysinit-nvim = {
      url = "github:roshbhatia/sysinit.nvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        changes.follows = "changes";
      };
    };
    hunk = {
      url = "github:modem-dev/hunk";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hunk-commit-log = {
      url = "github:sadick254/hunk-commit-log";
      flake = false;
    };
    hunk-viewed = {
      url = "github:jacegodk/hunk-viewed";
      flake = false;
    };
    prose-style = {
      url = "github:roshbhatia/prose-style/8d131f507a7a43a99f25cc4e16d97b75cf921a8e";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    tether = {
      url = "github:roshbhatia/tether/6943abef2b779473a1ca8e143dd74c7d46b2e4a1";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    citelock = {
      url = "github:roshbhatia/citelock/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    slk = {
      url = "github:gammons/slk/v0.42.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nuvim = {
      url = "github:roshbhatia/nu_plugin_nvim/main";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    meat = {
      url = "github:boldsoftware/meat";
      flake = false;
    };

    janestreet-skills = {
      url = "github:janestreet/agent_skills";
      flake = false;
    };

    ast-grep-skills = {
      url = "github:ast-grep/agent-skill";
      flake = false;
    };

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix/d43f0e74444c1f266c640fc49ce6ce6fb69d33c3";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix/c361746c7d630d98b972378290547c8d35542a7a";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs/bdbc5f8dd2ad6136bb2ccecb14f6ec343965b194";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };

  };

  outputs = inputs: import ./flake inputs;
}
