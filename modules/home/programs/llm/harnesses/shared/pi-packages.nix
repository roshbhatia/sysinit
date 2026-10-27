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
      (mkBuiltNpmPackage "pi-subagents" "0.83.0" "sha256-3eQP8L6QoYPrTjlH3e7lyr5+xVNJudfXRdUJH4UgUvs="
        "sha256-4nLUfr9DMGk7z8tJmwN5NLOX2tEF7h0KNlShabGgtKI="
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
      mkFetchedNpmPackage "pi-ask-user" "0.17.0"
        "sha256-VVdGQq9YARn3t971kMFtbXF+azP/mMsX8rqGq4lsLDA=";
    toolDisplay =
      mkFetchedNpmPackage "pi-tool-display" "0.5.0"
        "sha256-HP4Hb57+0BoVv4YJ4TjW7tzEXgvR3SZaVSE6lWmmSFg=";
    subdirContext =
      mkFetchedNpmPackage "pi-subdir-context" "1.1.7"
        "sha256-nPHuANl4j5Ank2ccLUQFLxRIxTPJCLF3G73NpU8xHnI=";

    webAccess = pkgs.buildNpmPackage {
      pname = "pi-web-access";
      passthru.npmName = "pi-web-access";
      version = "0.45.0";
      src = fetchNpmPkg {
        name = "pi-web-access";
        version = "0.45.0";
        hash = "sha256-Z1T4u1Qb1cnNC3ieVsp+AHEdYQH+/udtaT4dLueSw1I=";
      };
      postPatch = ''
        cp ${./locks/pi-web-access.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-XO5eW0ilnlkC7CIAD9lU3a+0pRuhUaeGVzDrHUyzSUE=";
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

    btw = mkFetchedNpmPackage "pi-btw" "0.8.0" "sha256-rY16r38X528qPOrFq7Xtca8jn/RZuB1KjJJCYMNkL9w=";

    piRetry =
      mkFetchedNpmPackage "@narumitw/pi-retry" "0.31.0"
        "sha256-ZsuEnt7D7chVVNqZmMkwglkbIVe67BbcVS9I3iaNuaI=";

    piVcc =
      mkFetchedNpmPackage "@monotykamary/pi-vcc" "0.8.15"
        "sha256-Vc+SM+EtSRy4sSzmQKWi1rmHXRtLKJ3spEyWH/W62yQ=";

    piPermissionSystem =
      (mkBuiltNpmPackage "@gotgenes/pi-permission-system" "41.0.0"
        "sha256-JzkkxWi/fsoLRuVYYpG3MBB7JWCUwOvOow8uJs9jDDg="
        "sha256-hmXxECmgpzQuSCaiQSOP1NTFu2gV1A2dLiVc9A7OZSY="
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
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.28.33"
        "sha256-paPZE4pg4vYRkeONzVgH1Jq685QgZN5cxqRxT5q8Lio="
        "sha256-XYD4Rf+dPryeoi2LkTuRQCHLZJaLPEFzEeNf3s+z/o0="
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
      npmDepsHash = "sha256-pEAEa18G7jduRCiWrb3qd1ggPSJkKgopoHBsplVgx1M=";
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
