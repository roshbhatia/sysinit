;;; sysinit-mail-core.el --- Mail core -*- lexical-binding: t; -*-


(require 'cl-lib)
(setq evil-want-keybinding nil
      evil-want-C-u-scroll t
      inhibit-startup-screen t
      initial-scratch-message nil
      make-backup-files nil
      auto-save-default nil)
(require 'evil)
(require 'notmuch)
(require 'notmuch-tree)
(require 'ansi-color)
(evil-mode 1)
(menu-bar-mode -1)
(setq notmuch-search-oldest-first nil
      notmuch-show-logo nil
      notmuch-hello-auto-refresh t
      notmuch-fcc-dirs nil
      notmuch-show-mark-read-tags nil
      message-send-mail-function #'message-send-mail-with-sendmail
      message-sendmail-envelope-from 'header
      message-sendmail-f-is-evil t
      message-kill-buffer-on-exit t
      notmuch-show-only-matching-messages t
      notmuch-tree-outline-enabled t
      notmuch-tree-outline-visibility nil
      notmuch-always-prompt-for-sender nil)


(provide 'sysinit-mail-core)
