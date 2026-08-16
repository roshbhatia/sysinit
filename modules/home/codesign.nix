{
  config,
  lib,
  pkgs,
  ...
}:
let
  paths = import ../shared/codesign.nix;
  cfg = config.sysinit.codesign;

  home = config.home.homeDirectory;
  keychain = "${home}/Library/Keychains/${paths.keychainName}";
  passwordFile = "${home}/${paths.passwordFile}";
  signedBinDir = "${home}/${paths.signedBinDir}";

  signer = pkgs.writeShellApplication {
    name = "sysinit-codesign";
    runtimeInputs = [ pkgs.openssl ];
    text = ''
      # security, codesign and sudo are Apple's and live outside the Nix path,
      # which home-manager activation does not inherit.
      export PATH="/usr/bin:/bin:/usr/sbin:$PATH"

      KEYCHAIN=${lib.escapeShellArg keychain}
      PW_FILE=${lib.escapeShellArg passwordFile}
      SIGNED_BIN=${lib.escapeShellArg signedBinDir}
      IDENTITY=${lib.escapeShellArg paths.identity}

      mkdir -p "$(dirname "$PW_FILE")" "$SIGNED_BIN"

      # The certificate lasts 20 years. Replacing it invalidates every grant it
      # ever earned, so the whole script is written to never re-create one that
      # already works.
      ensure_identity() {
        if security find-identity -v -p codesigning "$KEYCHAIN" 2>/dev/null | grep -q "$IDENTITY"; then
          return 0
        fi
        echo "sysinit-codesign: creating the signing identity" >&2

        if [ ! -f "$PW_FILE" ]; then
          LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 40 > "$PW_FILE"
          chmod 600 "$PW_FILE"
        fi
        local pw work
        pw="$(cat "$PW_FILE")"
        work="$(mktemp -d)"
        trap 'rm -rf "$work"' RETURN

        openssl req -x509 -newkey rsa:2048 -keyout "$work/key.pem" -out "$work/cert.pem" \
          -days 7300 -nodes -subj "/CN=$IDENTITY" \
          -addext "basicConstraints=critical,CA:false" \
          -addext "keyUsage=critical,digitalSignature" \
          -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null
        # -legacy: macOS Security.framework cannot read the AES-256 PKCS#12 that
        # OpenSSL 3 writes by default, and fails with "MAC verification failed".
        openssl pkcs12 -export -legacy -out "$work/id.p12" \
          -inkey "$work/key.pem" -in "$work/cert.pem" -passout "pass:$pw" 2>/dev/null

        security delete-keychain "$KEYCHAIN" 2>/dev/null || true
        security create-keychain -p "$pw" "$KEYCHAIN"
        # No timeout and no lock on sleep: activation has to sign without a prompt.
        security set-keychain-settings "$KEYCHAIN"
        security unlock-keychain -p "$pw" "$KEYCHAIN"
        security import "$work/id.p12" -k "$KEYCHAIN" -P "$pw" -A -T /usr/bin/codesign >/dev/null
        security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$pw" "$KEYCHAIN" >/dev/null 2>&1
        security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" "$work/cert.pem" >/dev/null
        # shellcheck disable=SC2046
        security list-keychains -d user -s $(security list-keychains -d user | tr -d ' "') "$KEYCHAIN"
      }

      ensure_identity
      security unlock-keychain -p "$(cat "$PW_FILE")" "$KEYCHAIN"

      LEAF="$(security find-identity -v -p codesigning "$KEYCHAIN" \
        | grep "$IDENTITY" | awk '{print $2}' | tr '[:upper:]' '[:lower:]')"
      if [ -z "$LEAF" ]; then
        echo "sysinit-codesign: no signing identity; skipping" >&2
        exit 0
      fi

      already_ours() {
        codesign -d -r- "$1" 2>&1 | grep -q "certificate leaf = H\"$LEAF\""
      }

      # A notarized app already has a stable, identity-based requirement. Re-signing
      # it would strip that and break the app, so only ad-hoc builds are touched.
      is_adhoc() {
        codesign -dv "$1" 2>&1 | grep -q "^Signature=adhoc"
      }

      sign() {
        local target="$1" sudo_prefix="''${2:-}"
        echo "sysinit-codesign: signing $target" >&2
        # shellcheck disable=SC2086
        $sudo_prefix codesign -f -s "$IDENTITY" --keychain "$KEYCHAIN" --deep \
          --timestamp=none "$target" 2>&1 | grep -v "replacing existing signature" || true
      }

      sign_app() {
        local app="$1" sudo_prefix="''${2:-}"
        if [ ! -d "$app" ]; then return 0; fi
        if ! is_adhoc "$app"; then return 0; fi
        if already_ours "$app"; then return 0; fi
        sign "$app" "$sudo_prefix"
      }

      # The marker records which store path the copy came from. Comparing the
      # files themselves would never match, because signing rewrites the copy.
      stage() {
        local name="$1" src="$2"
        local dest="$SIGNED_BIN/$name" marker="$SIGNED_BIN/.$name.src"
        if [ ! -f "$src" ]; then return 0; fi
        if [ -f "$dest" ] && [ "$(cat "$marker" 2>/dev/null)" = "$src" ] && already_ours "$dest"; then
          return 0
        fi
        install -m 755 "$src" "$dest"
        printf '%s' "$src" > "$marker"
        sign "$dest"
      }

      for app in "$HOME/Applications/Home Manager Apps"/*.app; do
        sign_app "$app"
      done

      # /Applications/Nix Apps is a root-owned copy that nix-darwin rewrites on
      # every switch. Skip rather than prompt when sudo needs a password.
      if sudo -n true 2>/dev/null; then
        for app in "/Applications/Nix Apps"/*.app; do
          sign_app "$app" "sudo -n"
        done
      else
        echo "sysinit-codesign: sudo needs a password; left /Applications/Nix Apps unsigned" >&2
      fi

      ${lib.concatMapStringsSep "\n" (name: ''
        stage ${lib.escapeShellArg name} ${lib.escapeShellArg cfg.binaries.${name}}
      '') (builtins.attrNames cfg.binaries)}
    '';
  };
in
{
  options.sysinit.codesign = {
    enable = lib.mkEnableOption "a stable code-signing identity so TCC grants survive a rebuild" // {
      default = pkgs.stdenv.hostPlatform.isDarwin;
    };

    binaries = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = ''
        Executables that launchd starts and that need a TCC permission, as
        name -> store path. Each is copied to a path that does not move and
        signed there, so its grant survives the next update.
      '';
      example = lib.literalExpression ''{ borders = "''${pkgs.jankyborders}/bin/borders"; }'';
    };

    signedBinDir = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = signedBinDir;
      description = "Where the staged, signed copies live. Point launchd here.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.sysinitCodesign = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe signer} || true
    '';
  };
}
