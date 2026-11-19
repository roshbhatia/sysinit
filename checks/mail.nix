{ pkgs }:
let
  emacs = (pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (
    import ../modules/home/programs/mail/packages.nix { inherit pkgs; }
  );
in
import ./native.nix { inherit pkgs; } {
  name = "mail-actions";
  inputs = [
    emacs
    pkgs.notmuch
    pkgs.chafa
    pkgs.imagemagick
  ];
  environment.MAIL_CONFIG = "${../modules/home/programs/mail/emacs}/sysinit-mail.el";
  commands = [
    [
      "emacs"
      "--batch"
      "-q"
      "-L"
      "${pkgs.notmuch.emacs}/share/emacs/site-lisp"
      "--load"
      ./mail.el
      "--funcall"
      "ert-run-tests-batch-and-exit"
    ]
  ];
}
