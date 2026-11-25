{ lib, pkgs }:
let
  fetchNpmPkg =
    {
      name,
      version,
      hash,
    }:
    let
      basename = lib.last (lib.splitString "/" name);
    in
    pkgs.fetchzip {
      url = "https://registry.npmjs.org/${name}/-/${basename}-${version}.tgz";
      inherit hash;
      passthru.npmName = name;
    };

  buildNpmPkg =
    {
      name,
      version,
      hash,
      npmDepsHash,
      lockFile,
    }:
    pkgs.buildNpmPackage {
      pname = name;
      inherit version npmDepsHash;
      passthru.npmName = name;
      src = fetchNpmPkg { inherit name version hash; };
      postPatch = ''
        cp ${lockFile} package-lock.json
      '';
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

  mkFetchedNpmPackage =
    name: version: hash:
    fetchNpmPkg {
      inherit name version hash;
    };

  mkBuiltNpmPackage =
    name: version: hash: npmDepsHash: lockFile:
    buildNpmPkg {
      inherit
        name
        version
        hash
        npmDepsHash
        lockFile
        ;
    };

  packages = {
    context =
      mkFetchedNpmPackage "pi-context" "2.3.0"
        "sha256-jhzTPMVHFoVQfXghRq1ap/8Z+iNoYyH2tnAzuO1Ev/g=";
    subagents =
      (mkBuiltNpmPackage "pi-subagents" "0.90.0" "sha256-oZs1RSGZOY/gOlvNYl+w3CRDrfu3A8dRJ74CZ1xZeyA="
        "sha256-n7Bcd+IwYcp/3q0I3F8pWQmfYEn5LDBhMw9mzR1CsGM="
        ./locks/pi-subagents.lock.json
      ).overrideAttrs
        {
          npmFlags = [
            "--ignore-scripts"
            "--legacy-peer-deps"
          ];
        };
    readlineSearch =
      mkFetchedNpmPackage "pi-readline-search" "0.1.0"
        "sha256-HxomHcIceZX68M0f0ZcRJSiqDzqCI0p+wcyq8CVL514=";
    threads =
      mkFetchedNpmPackage "pi-threads" "0.2.1"
        "sha256-MF++ANxMplxx0qydKoozrnNTFtb4HQ/0s923cGrsPyM=";
    librarian =
      mkFetchedNpmPackage "pi-librarian" "1.3.7"
        "sha256-Obn+DyQD1WCptZO5t0YgUOdpGULNYfPxUA7NeGT7GfQ=";
    askUser =
      mkFetchedNpmPackage "pi-ask-user" "0.17.2"
        "sha256-klpWruz50S62kC/GyHNoQgwnpBCgWJxJyzN4eRNxQiA=";
    subdirContext =
      mkFetchedNpmPackage "pi-subdir-context" "1.1.7"
        "sha256-nPHuANl4j5Ank2ccLUQFLxRIxTPJCLF3G73NpU8xHnI=";

    webAccess = pkgs.buildNpmPackage {
      pname = "pi-web-access";
      passthru.npmName = "pi-web-access";
      version = "0.48.0";
      src = fetchNpmPkg {
        name = "pi-web-access";
        version = "0.48.0";
        hash = "sha256-jEsoEm+Yre+vzbjCYpSsY1tID4Z6AiEZPuq86BkKLx8=";
      };
      postPatch = ''
        cp ${./locks/pi-web-access.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-5qPDamXFMbkRgqwyFK29PvRoIhti62Imze2Lul6HZ+Y=";
      npmFlags = [
        "--ignore-scripts"
        "--legacy-peer-deps"
      ];
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    btw = mkFetchedNpmPackage "pi-btw" "0.8.1" "sha256-dFZcjS7H74QnrjxYyoKZbaBD/cCbav+G900z5hfBEfQ=";

    piRetry =
      mkFetchedNpmPackage "@narumitw/pi-retry" "0.31.0"
        "sha256-ZsuEnt7D7chVVNqZmMkwglkbIVe67BbcVS9I3iaNuaI=";

    piVcc =
      mkFetchedNpmPackage "@monotykamary/pi-vcc" "0.8.17"
        "sha256-EfiUJDIRVPgNDTCLw8/GDdNBoieh19xO1eI9cmcjcfs=";

    piPermissionSystem =
      (mkBuiltNpmPackage "@gotgenes/pi-permission-system" "42.2.1"
        "sha256-+cizwqZEKAxEO5ii5OPzNBCMeZW+c8MuTXRV2kzfy3I="
        "sha256-PtE3B+nRYN8idXFQ7VJLb6lhwHKJ91RpAH6hCfjwDqg="
        ./locks/pi-permission-system.lock.json
      ).overrideAttrs
        {
          npmFlags = [
            "--ignore-scripts"
            "--omit=dev"
          ];
        };

    openaiFast =
      mkFetchedNpmPackage "@benvargas/pi-openai-fast" "1.1.2"
        "sha256-aRywGZq0Ml7vtBFn8YoCNevmDZgJ2TRZpNwRwPtDWlE=";

    openaiVerbosity =
      mkFetchedNpmPackage "@benvargas/pi-openai-verbosity" "1.2.0"
        "sha256-S5bqq5L6rr08OQ3S8UMru8uagRmMhEWYs1Emwaa5r/o=";

    plannotator =
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.29.3"
        "sha256-EkGNFNE4hmpLBiqdz2LiX8pIy/HiwCxhKoZAoG1pfzc="
        "sha256-JJrgm3gR+dQvILgCrxb2fmC52ED/G2IR5hja4fJ3dAU="
        ./locks/plannotator.lock.json;

    piReverseLast =
      mkBuiltNpmPackage "@firstpick/pi-extension-reverse-last" "0.2.2"
        "sha256-HHfLaCw2UCRkDRGK19tJlojiROXxx49vF1Kf5Cn/BYM="
        "sha256-FGPkUpAyfzD9VKfKgbepUUtVJbILiByEWiLfojh21PI="
        ./locks/pi-reverse-last.lock.json;

    diff = pkgs.buildNpmPackage {
      pname = "pi-diff";
      passthru.npmName = "@heyhuynhgiabuu/pi-diff";
      version = "0.9.3";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@heyhuynhgiabuu/pi-diff/-/pi-diff-0.9.3.tgz";
        hash = "sha256-FmRaccPvV0IpRNsLavrG29dPjfpVnbDn96wVDJlRh9g=";
      };
      postPatch = ''
        cp ${./locks/pi-diff.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-a7lMtLuJFiwRnCwcY3IO3tJ87n0XnbrMMvUOLGoO49A=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };
  };
in
{
  inherit
    fetchNpmPkg
    buildNpmPkg
    mkFetchedNpmPackage
    mkBuiltNpmPackage
    packages
    ;
}
