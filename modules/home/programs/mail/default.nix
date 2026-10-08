{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.mail;
  themeLib = import ../../../shared/theme-colors.nix { inherit lib; };
  colors = themeLib.colorsOf config;
  palette = lib.genAttrs (map (n: "base0${n}") [
    "0"
    "1"
    "2"
    "3"
    "4"
    "5"
    "6"
    "7"
    "8"
    "9"
    "A"
    "B"
    "C"
    "D"
    "E"
    "F"
  ]) (name: "#${colors.${name}}");
  accountFile = "${config.xdg.configHome}/email/accounts.json";
  mailEnv = ''
    export NOTMUCH_CONFIG=${lib.escapeShellArg "${config.xdg.configHome}/notmuch/default/config"}
    umask 077
  '';
  auth = pkgs.writeShellApplication {
    name = "mail-auth";
    runtimeInputs = [
      pkgs.notmuch
      pkgs.lieer
      pkgs.jq
    ];
    text = ''
      ${mailEnv}
      account="''${1:-personal}"
      if [[ $# -gt 0 ]]; then shift; fi
      path=$(jq -er --arg name "$account" '.[] | select(.name == $name) | .path' ${lib.escapeShellArg accountFile})
      notmuch new
      exec gmi auth --path "$path" "$@"
    '';
  };
  sync = pkgs.writeShellApplication {
    name = "mail-sync";
    runtimeInputs = [
      pkgs.lieer
      pkgs.jq
      pkgs.coreutils
      pkgs.gnugrep
    ];
    text = ''
      ${mailEnv}
      paths=$(jq -er '.[].path' ${lib.escapeShellArg accountFile})
      synced=0
      status=0
      output=$(mktemp)
      trap 'rm -f -- "$output"' EXIT
      while IFS= read -r path; do
        if [[ -s "$path/.credentials.gmailieer.json" ]]; then
          synced=1
          if gmi sync --path "$path" > "$output" 2>&1; then
            cat "$output"
          elif grep -Fxq 'lieer.local.Local.RepositoryException: failed to lock repository (probably in use by another gmi instance)' "$output"; then
            printf 'Sync already running: %s; changes will sync on the next pass.\n' "$path"
            if [[ "$status" == 0 ]]; then status=75; fi
          else
            cat "$output" >&2
            status=1
          fi
        fi
      done <<< "$paths"
      if [[ "$synced" == 0 ]]; then
        echo 'No account is signed in. Run mail-auth personal or mail-auth work.' >&2
        exit 1
      fi
      exit "$status"
    '';
  };
  imagePreview = pkgs.writeShellApplication {
    name = "email-image-preview";
    runtimeInputs = [
      pkgs.chafa
      pkgs.coreutils
    ];
    text = ''
      image="$1"
      trap 'rm -f -- "$image"' EXIT
      render() {
        chafa --format=iterm --animate=off --scale=max --clear -- "$image"
        printf '\nPress Enter to close.\n'
      }
      trap render WINCH
      render
      while true; do
        if read -r -t 0.25 _; then break; else
          preview_status=$?
          if [[ "$preview_status" -le 128 ]]; then break; fi
        fi
      done
    '';
  };
  init = pkgs.writeText "email-init.el" ''
    ;;; email-init.el --- Mail launcher -*- lexical-binding: t; -*-
    (add-to-list 'load-path "${pkgs.notmuch.emacs}/share/emacs/site-lisp")
    (require 'json)
    (let ((json-array-type 'list))
      (setq sysinit-mail-accounts
        (mapcar (lambda (account) (list (alist-get 'address account) (alist-get 'path account) (alist-get 'name account)))
          (json-read-file ${builtins.toJSON accountFile}))))
    (setq sysinit-mail-palette (json-parse-string ${builtins.toJSON (builtins.toJSON palette)} :object-type 'alist))
    (setq user-mail-address (caar sysinit-mail-accounts)
      user-full-name "Roshan Bhatia"
      sysinit-mail-state-file ${builtins.toJSON "${config.xdg.stateHome}/email/account"}
      sysinit-mail-firefox-command '(
        ${
          lib.concatMapStringsSep " " builtins.toJSON (
            if pkgs.stdenv.hostPlatform.isDarwin then
              [
                "/usr/bin/open"
                "-a"
                "Firefox"
              ]
            else
              [ (lib.getExe pkgs.firefox) ]
          )
        })
      sysinit-mail-sync-command ${builtins.toJSON (lib.getExe sync)}
      sysinit-mail-chafa-command ${builtins.toJSON "${pkgs.chafa}/bin/chafa"}
      sysinit-mail-image-command ${builtins.toJSON (lib.getExe imagePreview)}
      sendmail-program ${builtins.toJSON "${pkgs.lieer}/bin/gmi"})
    (load "${./emacs}/sysinit-mail.el")
  '';
  client = pkgs.writeTextFile {
    name = "email";
    destination = "/bin/email";
    executable = true;
    text =
      "#!${pkgs.nushell}/bin/nu --no-config-file\n"
      +
        builtins.replaceStrings
          (map builtins.toJSON [
            "@accounts@"
            "@config@"
            "@state@"
            "@notmuch@"
            "@emacs@"
            "@init@"
          ])
          (map builtins.toJSON [
            accountFile
            "${config.xdg.configHome}/notmuch/default/config"
            "${config.xdg.stateHome}/email/account"
            "${pkgs.notmuch}/bin/notmuch"
            "${config.programs.emacs.finalPackage}/bin/emacs"
            (toString init)
          ])
          (builtins.readFile ./email.nu);
  };

in
{
  options.sysinit.mail.enable = lib.mkEnableOption "Gmail in Emacs with notmuch and Lieer" // {
    default = true;
  };
  config = lib.mkIf cfg.enable {
    home.packages = [
      client
      auth
      sync
      pkgs.notmuch
      pkgs.lieer
      pkgs.imagemagick
      pkgs.libsixel
      pkgs.gmailctl
    ];
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-nox;
      extraPackages = import ./packages.nix { inherit pkgs; };
    };
  };
}
