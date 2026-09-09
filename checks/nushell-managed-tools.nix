{ lib, pkgs }:
let
  nushellLib = import ../modules/home/programs/nushell/lib.nix { inherit lib; };
  managedProfile = pkgs.buildEnv {
    name = "nushell-managed-tools-profile";
    paths = [
      pkgs.seshy
      pkgs.specutil
    ];
    pathsToLink = [
      "/bin"
      "/share/nushell"
    ];
  };

  userShims = pkgs.runCommand "nushell-unmanaged-tool-shims" { } ''
    mkdir -p "$out/bin"
    for name in sy specutil; do
      printf '#!${pkgs.runtimeShell}\nprintf "unmanaged %%s\\n" "$0"\n' > "$out/bin/$name"
      chmod +x "$out/bin/$name"
    done
  '';

  completionConfig = pkgs.writeText "nushell-managed-tool-completions.nu" (
    nushellLib.sourceCompletion pkgs.seshy "sy"
  );
in
pkgs.runCommand "nushell-managed-tools" { nativeBuildInputs = [ pkgs.nushell ]; } ''
  test -s ${pkgs.seshy}/share/nushell/vendor/autoload/sy.nu
  test -s ${managedProfile}/share/nushell/vendor/autoload/sy.nu
  test -s ${managedProfile}/share/nushell/vendor/autoload/specutil.nu

  ${pkgs.nushell}/bin/nu --no-config-file -c '
    use std/util "path add"
    $env.PATH = ["${userShims}/bin"]
    ${nushellLib.pathAdd [
      "${managedProfile}/bin"
      "${pkgs.coreutils}/bin"
    ]}

    let expected = ["${managedProfile}/bin" "${pkgs.coreutils}/bin" "${userShims}/bin"]
    if ($env.PATH | take 3) != $expected {
      error make {msg: "managed path order mismatch"}
    }

    let sy = (which sy | first | get path | into string)
    let specutil = (which specutil | first | get path | into string)
    if $sy != "${managedProfile}/bin/sy" {
      error make {msg: $"sy resolved to ($sy)"}
    }
    if $specutil != "${managedProfile}/bin/specutil" {
      error make {msg: $"specutil resolved to ($specutil)"}
    }
    if (^sy --version | str trim) != "sy version ${lib.getVersion pkgs.seshy}" {
      error make {msg: "managed sy version mismatch"}
    }
    if (^specutil --version | str trim) != "specutil version ${lib.getVersion pkgs.specutil}" {
      error make {msg: "managed specutil version mismatch"}
    }
  '

  ${pkgs.nushell}/bin/nu --config ${completionConfig} -c '
    let help_text = (help sy | to text)
    if not ($help_text | str contains "sy delete") {
      error make {msg: "help sy did not load Seshy completions"}
    }
  '

  touch $out
''
