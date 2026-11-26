let
  username = "rshnbhatia";

  git = {
    name = "Roshan Bhatia";
    email = "rshnbhatia@gmail.com";
    username = "roshbhatia";
    ssh.use1PasswordAgent = true;
  };

in
{
  inherit username git;

  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIWYK84u+ZlSasw3Z7LwsA2eT9S7xDXKVj61xOqAubKe rshnbhatia@lv426"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBPaCcHii525hx5Roh8kYyisdIjXVG3t4tkKwhcwUwXS rshnbhatia@arrakis"
  ];

  rosePine = {
    scheme = "Rosé Pine";
    author = "Emilia Dunfelt, corrected for base16 slot order";
    base00 = "191724";
    base01 = "1F1D2E";
    base02 = "26233A";
    base03 = "6E6A86";
    base04 = "908CAA";
    base05 = "E0DEF4";
    base06 = "E9E8F7";
    base07 = "F4F3FB";
    base08 = "EB6F92";
    base09 = "F6C177";
    base0A = "EBBCBA";
    base0B = "3E8FB0";
    base0C = "9CCFD8";
    base0D = "C4A7E7";
    base0E = "D096CE";
    base0F = "9C7F87";
  };

  linuxWorkstation = hardware: extraValues: {
    system = "x86_64-linux";
    platform = "linux";
    profile = "workstation";
    desktop = true;
    inherit username hardware;
    values = {
      wezterm.remoteMux = true;
      git = git // {
        ssh = {
          use1PasswordAgent = false;
          identityFile = "~/.ssh/id_ed25519_personal";
        };
      };
    }
    // extraValues;
  };
}
