{ pkgs }:
let
  emacs = (pkgs.emacsPackagesFor pkgs.emacs-nox).emacsWithPackages (ep: [ ep.evil ]);
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
    export MAIL_CONFIG=${../modules/home/programs/mail/mail.el}
    emacs --batch -q -L ${pkgs.notmuch.emacs}/share/emacs/site-lisp \
      --load ${./mail.el} --funcall ert-run-tests-batch-and-exit
    touch "$out"
  ''
