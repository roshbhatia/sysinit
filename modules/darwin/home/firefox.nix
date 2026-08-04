{
  pkgs,
  ...
}:

let
  firefoxWrapper =
    pkgs.runCommand "firefox-homebrew-wrapper"
      {
        pname = "firefox";
        version = "homebrew";
      }
      ''
        mkdir -p $out/bin
        cat > $out/bin/firefox <<EOF
        #!/bin/sh
        exec /Applications/Firefox.app/Contents/MacOS/firefox "\$@"
        EOF
        chmod +x $out/bin/firefox
      '';
in
{
  imports = [
    ../../home/programs/firefox.nix
  ];

  programs.firefox.package = firefoxWrapper // {
    override = _args: firefoxWrapper;
  };
}
