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

  work = {
    username = "roshan";
    values = {
      inherit git;
      theme.base16Scheme = "rose-pine-moon";
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
