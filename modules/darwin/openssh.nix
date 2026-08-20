{
  config,
  lib,
  ...
}:

let
  cfg = config.sysinit.darwin.openssh;
  inherit (config.sysinit.user) username;
in
{
  config = lib.mkIf cfg.enable {
    services.openssh = {
      # This flips Remote Login on by running `launchctl enable
      # system/com.openssh.sshd` and bootstrapping
      # /System/Library/LaunchDaemons/ssh.plist. nix-darwin refuses to call
      # `systemsetup -setremotelogin` on purpose, because that needs Full Disk
      # Access, so a switch never prompts for it.
      enable = true;

      # /etc/ssh/sshd_config includes sshd_config.d/* on line 19, ahead of its
      # own AuthorizedKeysFile and defaults, and sshd keeps the first value it
      # obtains for a keyword. The glob is lexical, so Apple's 100-macos.conf is
      # read before 100-nix-darwin.conf; nothing below restates what Apple sets.
      #
      # KbdInteractiveAuthentication has to be named as well as
      # PasswordAuthentication. Apple's file sets `UsePAM yes`, and PAM serves a
      # password through keyboard-interactive even when password auth is off.
      #
      # There is no AllowUsers line. Access is already gated by the
      # com.apple.access_ssh service ACL, which nests the admin group, and a
      # single-user allowlist would lock out any account a device-management
      # agent needs.
      extraConfig = ''
        PasswordAuthentication no
        KbdInteractiveAuthentication no
        PermitRootLogin no
      '';
    };

    # Not ~/.ssh/authorized_keys. nix-darwin writes
    # /etc/ssh/nix_authorized_keys.d/$USER and feeds it to sshd through
    # AuthorizedKeysCommand, which sshd reads in addition to the user's own
    # file. That separation is load-bearing on a managed Mac: the JumpCloud
    # agent owns ~/.ssh/authorized_keys there and rewrites it, so a key placed
    # in that file does not survive.
    users.users.${username}.openssh.authorizedKeys.keys = cfg.authorizedKeys;
  };
}
