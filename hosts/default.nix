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
    base00 = "362129"; # default bg
    base01 = "1C1D1F"; # status bars / lighter bg (ansi 0)
    base02 = "27282A"; # selection bg
    base03 = "666068"; # comments / invisibles (ansi 8 bright black)
    base04 = "766D76"; # dim foreground (ansi 7 white)
    base05 = "C4B6C5"; # default foreground
    base06 = "D4C6D5"; # light foreground
    base07 = "E4D6E5"; # lightest
    base08 = "C4959C"; # vars / diff-deleted (ansi 9 bright red)
    base09 = "A18877"; # integers / constants — orange (ansi 3 yellow)
    base0A = "C9AA95"; # classes / search (ansi 11 bright yellow)
    base0B = "9BBDB8"; # strings (ansi 10 bright green)
    base0C = "5F86B0"; # support / regex (ansi 14 bright cyan)
    base0D = "96AFF2"; # functions (ansi 12 bright blue)
    base0E = "A6A4EB"; # keywords (ansi 13 bright magenta)
    base0F = "9D777D"; # deprecated / embedded (ansi 1 red)
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
