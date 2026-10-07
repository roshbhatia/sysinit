{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.mail;
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
    ];
    text = ''
      ${mailEnv}
      paths=$(jq -er '.[].path' ${lib.escapeShellArg accountFile})
      synced=0
      while IFS= read -r path; do
        if [[ -s "$path/.credentials.gmailieer.json" ]]; then
          gmi sync --path "$path"
          synced=1
        fi
      done <<< "$paths"
      if [[ "$synced" == 0 ]]; then
        echo 'No account is signed in. Run mail-auth personal or mail-auth work.' >&2
        exit 1
      fi
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
    (setq user-mail-address (caar sysinit-mail-accounts)
      user-full-name "Roshan Bhatia"
      sysinit-mail-state-file ${builtins.toJSON "${config.xdg.stateHome}/email/account"}
      sysinit-mail-sync-command ${builtins.toJSON (lib.getExe sync)}
      sendmail-program ${builtins.toJSON "${pkgs.lieer}/bin/gmi"})
    ${builtins.readFile ./mail.el}
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
      pkgs.gmailctl
    ];
    programs.emacs = {
      enable = true;
      package = pkgs.emacs-nox;
      extraPackages = ep: [ ep.evil ];
    };
  };
}
