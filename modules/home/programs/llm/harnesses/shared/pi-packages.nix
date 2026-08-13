# The pi extension package set, shared by every harness in the pi lineage.
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

    mermaid = pkgs.buildNpmPackage {
      pname = "pi-mermaid";
      passthru.npmName = "pi-mermaid";
      version = "0.3.0";
      src = pkgs.fetchFromGitHub {
        owner = "Gurpartap";
        repo = "pi-mermaid";
        rev = "34cab3ae794422d43707f129120a73ea39f51742";
        hash = "sha256-tXFYBlFjXUR4TF6k0FWC9T6kxWjlF/kAEt/Q9/nUCJY=";
      };
      npmDepsHash = "sha256-rHFkSF+v9MeXXfq8x7Vl9al7EmLgGrC1AMH+WVyxviA=";
      npmFlags = "--ignore-scripts";
      dontNpmBuild = true;
      installPhase = ''
        runHook preInstall
        cp -r . $out
        runHook postInstall
      '';
    };

    context =
      mkFetchedNpmPackage "pi-context" "1.1.4"
        "sha256-pdRI1D2KIOJVV164DKpzXAQneOOEypB2GXqFzGRvasc=";
    subagents =
      mkFetchedNpmPackage "pi-subagents" "0.24.2"
        "sha256-cRcUl0gNmk4gqStqNffT6FQOozjAMuETe3OeNaQMXfA=";
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
      mkFetchedNpmPackage "pi-ask-user" "0.11.0"
        "sha256-R1TN2GWrwv3UhlAC0Ym1nMZABi/IrLxtD6EYxbDEfm8=";
    toolDisplay =
      mkFetchedNpmPackage "pi-tool-display" "0.3.6"
        "sha256-6ykaEl8IlwH667YQ+CBO/I/0rTDlIues4fYZDKJg2JE=";
    subdirContext =
      mkFetchedNpmPackage "pi-subdir-context" "1.1.7"
        "sha256-nPHuANl4j5Ank2ccLUQFLxRIxTPJCLF3G73NpU8xHnI=";

    webAccess = pkgs.buildNpmPackage {
      pname = "pi-web-access";
      passthru.npmName = "pi-web-access";
      version = "0.13.0";
      src = fetchNpmPkg {
        name = "pi-web-access";
        version = "0.13.0";
        hash = "sha256-6d/cX9OYHIxZ81fJgEu4L7DzMF/o63AL2/n/3zHs0DU=";
      };
      postPatch = ''
        cp ${./locks/pi-web-access.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-8onTvv7nUrTXMGvwkMkPEYc+mtpxolzF6Z9EuuB9pbs=";
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

    btw = mkFetchedNpmPackage "pi-btw" "0.4.0" "sha256-8iAnayDUtK/BGl0ldJ9klOpItdCyV8qniSO+pXGslNo=";

    piRetry =
      mkFetchedNpmPackage "@narumitw/pi-retry" "0.22.0"
        "sha256-TwMvcJLe4ldgRw8k6/bsQpJbkePKYww20CqZVQfvsAc=";

    piVcc =
      mkFetchedNpmPackage "@monotykamary/pi-vcc" "0.8.1"
        "sha256-hsk/cwirBtfYK77aMoCoFncYhMsCff+HyBnpZD0GJKU=";

    piPermissionSystem =
      mkBuiltNpmPackage "@gotgenes/pi-permission-system" "5.14.1"
        "sha256-/qNC6erD+Rl12JpLlFwe2N2PgaekpfMHHprnKozN1rk="
        "sha256-Dvu/wuGdwjBQsJCU0N8oI+a1EysJpHFkwLwUpgjJfso="
        ./locks/pi-permission-system.lock.json;

    openaiFast =
      mkFetchedNpmPackage "@benvargas/pi-openai-fast" "1.0.2"
        "sha256-cUY9RGofE+zMlB1qcgkM55KJhEiVHnan9bWSXtvpQ4E=";

    openaiVerbosity =
      mkFetchedNpmPackage "@benvargas/pi-openai-verbosity" "1.0.0"
        "sha256-FXjeNW4UVe5PwNjjr2pL6DrLcYkdNtr7yP4jTzQvyPw=";

    plannotator =
      mkBuiltNpmPackage "@plannotator/pi-extension" "0.19.14"
        "sha256-kyiItKnuYMxp43+5wlC6BUDftp+mTxXG7PB3aEq9Qbg="
        "sha256-oiiZsd1UG1nIa7xhnOcUKpyr2J2qWbghXildxE036Ok="
        ./locks/plannotator.lock.json;

    piReverseLast =
      mkBuiltNpmPackage "@firstpick/pi-extension-reverse-last" "0.1.4"
        "sha256-+NtvjE1W8roNwgR55hzzcJWM4xhSqtk9mKDEWCoEUUE="
        "sha256-k0e9qvB9tvt6qstrYnoH7tyOoB5qRwStzE+cBdRm7CQ="
        ./locks/pi-reverse-last.lock.json;

    diff = pkgs.buildNpmPackage {
      pname = "pi-diff";
      passthru.npmName = "@heyhuynhgiabuu/pi-diff";
      version = "0.3.0";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@heyhuynhgiabuu/pi-diff/-/pi-diff-0.3.0.tgz";
        hash = "sha256-lQ9V8DvaHCj7hG9q+SJwy7M9hDCOPXRfWTqBh9kjS9A=";
      };
      postPatch = ''
        cp ${./locks/pi-diff.lock.json} package-lock.json
      '';
      npmDepsHash = "sha256-DPZfPc5njMabDdo5UwX7UoWvHPwC261LhT8BsAm7U00=";
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
