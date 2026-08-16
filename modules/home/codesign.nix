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
  certFile = "${home}/${paths.certFile}";
  signedBinDir = "${home}/${paths.signedBinDir}";

  signer = pkgs.writeShellApplication {
    name = "sysinit-codesign";
    runtimeInputs = [ pkgs.openssl ];
    text = ''
      # security, codesign and sudo are Apple's and live outside the Nix path,
      # which home-manager activation does not inherit.
      export PATH="/usr/bin:/bin:/usr/sbin:$PATH"

      # nh swallows activation output, and a signature that silently fails to
      # apply reads exactly like one that was never attempted.
      exec 2> >(tee -a /tmp/sysinit-codesign.log >&2)
      echo "--- $(date '+%Y-%m-%d %H:%M:%S') mode=''${1:-user} uid=$(id -u)" >&2

      KEYCHAIN=${lib.escapeShellArg keychain}
      PW_FILE=${lib.escapeShellArg passwordFile}
      CERT_FILE=${lib.escapeShellArg certFile}
      SIGNED_BIN=${lib.escapeShellArg signedBinDir}
      IDENTITY=${lib.escapeShellArg paths.identity}

      # nix-darwin rewrites /Applications/Nix Apps from the store after
      # home-manager has run, which drops any signature written before it. Root
      # signs that directory afterwards, in system mode.
      MODE="''${1:-user}"

      if [ "$MODE" = "user" ]; then
        mkdir -p "$(dirname "$PW_FILE")" "$SIGNED_BIN"
      fi

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
        install -m 644 "$work/cert.pem" "$CERT_FILE"
        # shellcheck disable=SC2046
        security list-keychains -d user -s $(security list-keychains -d user | tr -d ' "') "$KEYCHAIN"
      }

      # `add-trusted-cert -k <keychain>` records trust for this user only, and the
      # system signing step runs as root. Without trust in the admin domain root
      # sees no valid identity and signs nothing.
      ensure_system_trust() {
        if [ ! -s "$CERT_FILE" ]; then
          security find-certificate -c "$IDENTITY" -p "$KEYCHAIN" > "$CERT_FILE" 2>/dev/null || return 0
        fi
        if sudo -n security find-certificate -c "$IDENTITY" \
          /Library/Keychains/System.keychain >/dev/null 2>&1; then
          return 0
        fi
        if ! sudo -n true 2>/dev/null; then
          echo "sysinit-codesign: sudo needs a password; /Applications/Nix Apps stays unsigned" >&2
          return 0
        fi
        echo "sysinit-codesign: trusting the certificate for every user" >&2
        sudo -n security add-trusted-cert -d -r trustRoot -p codeSign \
          -k /Library/Keychains/System.keychain "$CERT_FILE" >/dev/null
      }

      # Only the owner creates the identity. Root would create it owned by root,
      # and the user could then never unlock it.
      if [ "$MODE" = "user" ]; then
        ensure_identity
        ensure_system_trust
      elif [ ! -f "$PW_FILE" ]; then
        echo "sysinit-codesign: no identity yet; the next switch signs these" >&2
        exit 0
      fi
      # codesign searches the calling user's own keychain list, and root's does
      # not hold the owner's keychain. `-s` replaces the whole list, so the login
      # keychain is named explicitly: dropping it costs the user every saved
      # credential, git's included.
      if ! security list-keychains -d user | tr -d ' "' | grep -qx "$KEYCHAIN"; then
        local_login="$HOME/Library/Keychains/login.keychain-db"
        # shellcheck disable=SC2046
        security list-keychains -d user -s \
          $(security list-keychains -d user | tr -d ' "') \
          $([ -f "$local_login" ] && echo "$local_login") \
          /Library/Keychains/System.keychain "$KEYCHAIN" \
          2>/dev/null || true
      fi
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

      # No already_ours check here. home-manager rsyncs these bundles from the
      # store on every activation, and codesign reports the signature it saw
      # before that copy, so a skip decision made from it silently leaves the
      # unsigned version in place. Signing an already-signed bundle costs
      # seconds; skipping one wrongly costs a permission prompt.
      sign_app() {
        local app="$1" sudo_prefix="''${2:-}"
        if [ ! -d "$app" ]; then return 0; fi
        if ! is_adhoc "$app"; then return 0; fi
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

      if [ "$MODE" = "system" ]; then
        for app in "/Applications/Nix Apps"/*.app; do
          sign_app "$app"
        done
        exit 0
      fi

      for app in "$HOME/Applications/Home Manager Apps"/*.app; do
        sign_app "$app"
      done

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

    package = lib.mkOption {
      type = lib.types.package;
      readOnly = true;
      default = signer;
      description = "The signer. Run it with `system` from a root activation step.";
    };
  };

  config = lib.mkIf cfg.enable {
    home.activation.sysinitCodesign = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${lib.getExe signer} || true
    '';
  };
}
