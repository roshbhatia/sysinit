_:
let
  common = {
    username = "rshnbhatia";
    git = {
      name = "Roshan Bhatia";
      email = "rshnbhatia@gmail.com";
      username = "roshbhatia";
      personalEmail = "rshnbhatia@gmail.com";
      personalUsername = "roshbhatia";
      defaultIdentity = "personal";

      ssh = {
        use1PasswordAgent = true;
        personalPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPaCcHii525hx5Roh8kYyisdIjXVG3t4tkKwhcwUwXS";
      };
    };
  };

  mkGit =
    {
      workPublicKey ? null,
      workEmail ? null,
      workUsername ? null,
      defaultIdentity ? "personal",
      use1PasswordAgent ? true,
      workKeyFile ? null,
      personalKeyFile ? null,
    }:
    common.git
    // {
      inherit defaultIdentity;
    }
    // (if workEmail != null then { inherit workEmail; } else { })
    // (if workUsername != null then { inherit workUsername; } else { })
    // {
      ssh =
        common.git.ssh
        // {
          inherit use1PasswordAgent;
        }
        // (if workPublicKey != null then { inherit workPublicKey; } else { })
        // (if workKeyFile != null then { inherit workKeyFile; } else { })
        // (if personalKeyFile != null then { inherit personalKeyFile; } else { });
    };

  linuxGit = mkGit {
    use1PasswordAgent = false;
    personalKeyFile = "~/.ssh/id_ed25519_personal";
    workKeyFile = "~/.ssh/id_ed25519_work";
  };
in
{
  lv426 = {
    system = "aarch64-darwin";
    platform = "darwin";
    inherit (common) username;

    values = {
      git = mkGit {
        workPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMLPtliVrOLXXcbDdMgHQ6ln2yL/LV6nHR63355yQNeE";
        personalKeyFile = "~/.ssh/id_ed25519_personal";
      };
      environment = {
        LIMA_INSTANCE = "nostromo";
      };
    };
  };

  nostromo = {
    system = "aarch64-linux";
    platform = "linux";
    lima = true;
    inherit (common) username;

    values = {
      git = linuxGit;
    };
  };

  arrakis = {
    system = "x86_64-linux";
    platform = "linux";
    desktop = true;
    hardware = ../modules/nixos/hardware/arrakis.nix;
    inherit (common) username;

    values = {
      git = linuxGit;
      theme = {
        colorscheme = "rose-pine";
        variant = "dawn";
        appearance = "light";
        font = {
          monospace = "Iosevka Nerd Font";
        };
      };
    };
  };
}
