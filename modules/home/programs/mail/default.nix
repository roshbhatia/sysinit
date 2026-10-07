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
        (mapcar (lambda (account) (list (alist-get 'address account) (alist-get 'path account)))
          (json-read-file ${builtins.toJSON accountFile}))))
    (setq user-mail-address (caar sysinit-mail-accounts)
      user-full-name "Roshan Bhatia"
      sysinit-mail-sync-command ${builtins.toJSON (lib.getExe sync)}
      sendmail-program ${builtins.toJSON "${pkgs.lieer}/bin/gmi"})
    ${builtins.readFile ./mail.el}
  '';
  client = pkgs.writeShellApplication {
    name = "email";
    runtimeInputs = [ pkgs.notmuch ];
    text = ''
      ${mailEnv}
      if [[ ! -r ${lib.escapeShellArg accountFile} ]]; then
        echo 'Mail accounts are not configured. See the email setup guide.' >&2
        exit 1
      fi
      notmuch new
      exec ${config.programs.emacs.finalPackage}/bin/emacs -nw -q --load ${init} --funcall notmuch "$@"
    '';
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
