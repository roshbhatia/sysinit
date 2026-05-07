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
    base00 = "1C1825"; # default bg — dark grey-plum, leaning plum
    base01 = "23202E"; # status bars / lighter bg (ansi 0)
    base02 = "2E2A3C"; # selection bg
    base03 = "5C5872"; # comments / invisibles (ansi 8 bright black)
    base04 = "847F96"; # dim foreground (ansi 7 white)
    base05 = "C0BCD0"; # default foreground
    base06 = "D0CCDF"; # light foreground
    base07 = "E1DDEC"; # lightest
    base08 = "C58594"; # vars / love — dusty pink-red (ansi 9 bright red)
    base09 = "C49B7A"; # integers / constants — muted gold (ansi 3 yellow)
    base0A = "D5C497"; # classes / search — soft rose-yellow (ansi 11 bright yellow)
    base0B = "8FB5A8"; # strings — foam-pine green (ansi 10 bright green)
    base0C = "7895B0"; # support / regex — desaturated pine (ansi 14 bright cyan)
    base0D = "94A8D0"; # functions — soft foam-blue (ansi 12 bright blue)
    base0E = "B0A0CC"; # keywords — desaturated iris (ansi 13 bright magenta)
    base0F = "9C7080"; # deprecated / embedded — dark dusty rose (ansi 1 red)
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
