{ pkgs }:
let
  emacs = (pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (
    import ../modules/home/programs/mail/packages.nix
  );
in
pkgs.runCommand "mail-actions"
  {
    nativeBuildInputs = [
      emacs
      pkgs.notmuch
      pkgs.chafa
      pkgs.coreutils
    ];
  }
  ''
    export MAIL_CONFIG=${../modules/home/programs/mail/emacs}/sysinit-mail.el
    emacs --batch -q -L ${pkgs.notmuch.emacs}/share/emacs/site-lisp \
      --load ${./mail.el} --funcall ert-run-tests-batch-and-exit
    touch "$out"
  ''
