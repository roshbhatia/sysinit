;;; sysinit-mail.el --- Mail module entrypoint -*- lexical-binding: t; -*-

(add-to-list 'load-path (file-name-directory (or load-file-name buffer-file-name)))
(require 'sysinit-mail-core)
(require 'sysinit-mail-accounts)
(require 'sysinit-mail-actions)
(require 'sysinit-mail-views)
(require 'sysinit-mail-images)
(require 'sysinit-mail-ui)
(require 'sysinit-mail-keys)
(require 'sysinit-mail-sync)
