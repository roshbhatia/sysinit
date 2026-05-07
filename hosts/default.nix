_:
let
  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
    ssh.use1PasswordAgent = true;
  };

  personal = {
    username = "rshnbhatia";
    values = {
      inherit git;
      personal = true;
    };
  };

  roseprime = {
    scheme = "rosefine";
    author = "Roshan Bhatia";
    base00 = "2E1B22"; # default bg — wine, pulled back
    base01 = "1F1418"; # status bars / lighter bg (ansi 0)
    base02 = "33222A"; # selection bg
    base03 = "6E5862"; # comments / invisibles (ansi 8 bright black)
    base04 = "80707A"; # dim foreground (ansi 7 white)
    base05 = "C4B6C5"; # default foreground
    base06 = "D4C6D5"; # light foreground
    base07 = "E4D6E5"; # lightest
    base08 = "D29DA4"; # vars / diff-deleted (ansi 9 bright red)
    base09 = "B5917A"; # integers / constants — orange (ansi 3 yellow)
    base0A = "D2AE99"; # classes / search (ansi 11 bright yellow)
    base0B = "A5C2BD"; # strings (ansi 10 bright green)
    base0C = "6E91B8"; # support / regex (ansi 14 bright cyan)
    base0D = "9EB6F2"; # functions (ansi 12 bright blue)
    base0E = "AEA9ED"; # keywords (ansi 13 bright magenta)
    base0F = "AB7E84"; # deprecated / embedded (ansi 1 red)
  };

  work = {
    username = "roshan";
    values = {
      inherit git;
      theme.base16Scheme = roseprime;
    };
  };

  darwinHost = identity: limaPartner: extraValues: {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (identity) username;
    values =
      identity.values
      // {
        environment.LIMA_INSTANCE = limaPartner;
      }
      // extraValues;
  };

  limaHost = identity: {
    system = "aarch64-linux";
    platform = "linux";
    lima = true;
    inherit (identity) username;
    inherit (identity) values;
  };
in
{
  lv426 = darwinHost personal "nostromo" { };

  nostromo = limaHost personal;

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    desktop = true;
    hardware = ../modules/nixos/hardware/arrakis.nix;
    inherit (personal) username;
    values = personal.values // {
      theme = {
        base16Scheme = "everforest-dark-soft";
        font.monospace = "WumpusMono Nerd Font Mono";
      };
    };
  };

  hyperion = darwinHost work "farcaster" {
    darwin = {
      lima.instanceName = "farcaster";
      colima = {
        cpu = 4;
        memory = 8;
      };
      homebrew.additionalPackages = {
        taps = [
          "bastionzero/tap"
          "pinginc/lrl"
          "spacelift-io/spacelift"
        ];
        brews = [
          "awscli"
          "bastionzero/tap/zli"
        ];
        casks = [
          "sdm"
          "spacelift-io/spacelift/spacectl"
          "pinginc/lrl/lrl"
        ];
      };
    };
  };

  farcaster = limaHost work;
}
