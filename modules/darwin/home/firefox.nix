# Darwin-specific Firefox wrapper — imports shared config, adds macOS package
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
  # Import the shared firefox config (extensions, policies, search, theming)
  imports = [
    ../../home/programs/firefox.nix
  ];

  # Override package with macOS homebrew wrapper
  programs.firefox.package = firefoxWrapper // {
    override = _args: firefoxWrapper;
  };
}
