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

  rosefine = {
    scheme = "rosefine";
    author = "Roshan Bhatia";
    base00 = "1A0F14"; # default bg — dark grey-plum, leaning plum
    base01 = "23202E"; # status bars / lighter bg (ansi 0)
    base02 = "2E2A3C"; # selection bg
    base03 = "9692AB"; # comments / invisibles (ansi 8 bright black) — 4.69:1
    base04 = "A8A5B5"; # dim foreground (ansi 7 white) — 5.84:1
    base05 = "C0BCD0"; # default foreground — 7.61:1
    base06 = "D0CCDF"; # light foreground
    base07 = "E1DDEC"; # lightest
    base08 = "D19DA9"; # vars / love — dusty pink-red (ansi 9 bright red) — 6.10:1
    base09 = "C49B7A"; # integers / constants — muted gold (ansi 3 yellow) — 5.57:1
    base0A = "D5C497"; # classes / search — soft rose-yellow (ansi 11 bright yellow) — 8.16:1
    base0B = "8FB5A8"; # strings — foam-pine green (ansi 10 bright green) — 6.26:1
    base0C = "97ADC2"; # support / regex — desaturated pine (ansi 14 bright cyan) — 6.08:1
    base0D = "94A8D0"; # functions — soft foam-blue (ansi 12 bright blue) — 5.88:1
    base0E = "B0A0CC"; # keywords — desaturated iris (ansi 13 bright magenta) — 5.86:1
    base0F = "B4939F"; # deprecated / embedded — dusty rose (ansi 1 red) — 5.10:1
  };

  work = {
    username = "roshan";
    values = {
      inherit git;

      theme.base16Scheme = "everforest-dark-soft";
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
        base16Scheme = rosefine;
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
