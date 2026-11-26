{ pkgs }:
let
  inherit (pkgs) lib;
  manifest = builtins.fromJSON (builtins.readFile ./pi-types/package.json);
  piVersion = pkgs.pi-coding-agent.version;
in
assert manifest.devDependencies."@earendil-works/pi-coding-agent" == piVersion;
assert manifest.devDependencies."@earendil-works/pi-tui" == piVersion;
pkgs.buildNpmPackage {
  pname = "sysinit-pi-extension-typecheck";
  version = piVersion;
  src = ./pi-types;
  npmDepsHash = lib.strings.trim (builtins.readFile ./pi-types/npm-deps-hash);
  npmFlags = [ "--ignore-scripts" ];
  nativeBuildInputs = [ pkgs.typescript ];
  dontNpmBuild = true;

  buildPhase = ''
    runHook preBuild
    cp -r ${../../modules/home/programs/llm/harnesses/pi/extensions} extensions
    tsc --project tsconfig.json
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    touch "$out"
    runHook postInstall
  '';
}
