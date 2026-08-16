final: _prev:
let
  version = "0.5.0";
in
{
  # A stopgap, not a package. calldiff ships only to npm and pulls native
  # tree-sitter bindings that node-gyp builds, which `buildNpmPackage
  # --ignore-scripts` skips and the sandbox cannot run. So this wrapper pins the
  # version and lets npx fetch it into the user's npm cache on first use.
  #
  # What that costs, and why it is accepted here: the first run needs network and
  # takes about 20 seconds, nothing is in the nix store, and `nix develop` does
  # not carry it hermetically. Replace this with a real derivation once
  # tree-sitter builds under the sandbox on aarch64-darwin.
  calldiff = final.writeShellApplication {
    name = "calldiff";
    runtimeInputs = [ final.nodejs ];
    text = ''
      exec npx --yes calldiff@${version} "$@"
    '';
  };
}
