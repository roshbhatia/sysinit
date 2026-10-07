{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.sysinit.mail;
  tokenPath = name: "${config.xdg.stateHome}/mail/${name}.tokens";
  oauth = pkgs.writeShellApplication {
    name = "mail-oauth";
    runtimeInputs = [
      pkgs.python3
      pkgs.gnupg
    ];
    text = ''
      exec python3 ${pkgs.neomutt}/share/neomutt/oauth2/mutt_oauth2.py \
        --encryption-pipe ${
          lib.escapeShellArg (
            lib.escapeShellArgs [
              "gpg"
              "--encrypt"
              "--recipient"
              cfg.gpgKey
            ]
          )
        } \
        --decryption-pipe 'gpg --decrypt' "$@"
    '';
  };
  login =
    name: address:
    pkgs.writeShellApplication {
      name = "mail-auth-${name}";
      text = ''
        exec ${lib.getExe oauth} ${lib.escapeShellArg (tokenPath name)} \
          --authorize --provider google --email ${lib.escapeShellArg address} \
          --authflow localhostauthcode "$@"
      '';
    };
  account = name: address: {
    inherit address;
    realName = "Roshan Bhatia";
    primary = name == "personal";
    flavor = "gmail.com";
    userName = address;
    folders = {
      inbox = "INBOX";
      drafts = "[Gmail]/Drafts";
      sent = "[Gmail]/Sent Mail";
      trash = "[Gmail]/Trash";
    };
    neomutt = {
      enable = true;
      mailboxType = "imap";
      mailboxName = name;
      extraMailboxes = [
        { mailbox = "[Gmail]/All Mail"; }
        { mailbox = "[Gmail]/Sent Mail"; }
        { mailbox = "[Gmail]/Drafts"; }
      ]
      ++ lib.optionals (name == "personal") [
        { mailbox = "Unsubscribe"; }
        { mailbox = "Unsubscribe Success"; }
        { mailbox = "Unsubscribe Failed"; }
      ];
      extraConfig = ''
        set imap_user = "${address}"
        set imap_authenticators = "oauthbearer:xoauth2"
        set smtp_authenticators = "oauthbearer:xoauth2"
        set imap_oauth_refresh_command = "${lib.getExe oauth} ${tokenPath name}"
        set smtp_oauth_refresh_command = "${lib.getExe oauth} ${tokenPath name}"
        set smtp_url = "smtp://${lib.replaceStrings [ "@" ] [ "%40" ] address}@smtp.gmail.com:587/"
        set ssl_starttls = yes
        set ssl_force_tls = yes
      '';
    };
  };
in
{
  options.sysinit.mail = {
    enable = lib.mkEnableOption "Gmail terminal mail" // {
      default = true;
    };
    accounts = lib.mkOption {
      type = lib.types.attrsOf (lib.types.strMatching "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+");
      default.personal = "rshnbhatia@gmail.com";
      description = "Google mail addresses indexed by account name. Personal is the default account.";
    };
    gpgKey = lib.mkOption {
      type = lib.types.str;
      default = "rshnbhatia@gmail.com";
      description = "GPG recipient for NeoMutt's encrypted token files.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.accounts ? personal;
        message = "sysinit.mail.accounts must define the personal primary account.";
      }
      {
        assertion = lib.all (name: builtins.match "[a-z][a-z0-9-]*" name != null) (
          lib.attrNames cfg.accounts
        );
        message = "sysinit.mail account names must use lowercase letters, digits, and hyphens.";
      }
    ];
    home.packages = [
      oauth
      pkgs.gmailctl
    ]
    ++ lib.mapAttrsToList login cfg.accounts;
    accounts.email.accounts = lib.mapAttrs account cfg.accounts;
    home.activation.mailState = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run ${pkgs.coreutils}/bin/install -d -m 700 ${lib.escapeShellArg "${config.xdg.stateHome}/mail"}
    '';
    programs.neomutt = {
      enable = true;
      vimKeys = true;
      editor = "nvim";
      sort = "reverse-date";
      sidebar.enable = true;
      settings = {
        copy = "no";
        move = "no";
        mark_old = "no";
        confirmappend = "no";
        confirmcreate = "yes";
        mail_check = "60";
        timeout = "30";
      };
      extraConfig = builtins.readFile ./keys.rc;
    };
  };
}
