;;; mail.el --- Terminal mail client -*- lexical-binding: t; -*-

(require 'cl-lib)
(setq evil-want-keybinding nil
      evil-want-C-u-scroll t
      inhibit-startup-screen t
      initial-scratch-message nil
      make-backup-files nil
      auto-save-default nil)
(require 'evil)
(require 'notmuch)
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
      notmuch-identities (mapcar #'car sysinit-mail-accounts)
      notmuch-always-prompt-for-sender (> (length sysinit-mail-accounts) 1)
      notmuch-saved-searches
      '((:name "Primary" :query "path:personal/** and tag:inbox and tag:personal" :key "1")
        (:name "Promotions" :query "path:personal/** and tag:inbox and tag:promotions" :key "2")
        (:name "Social" :query "path:personal/** and tag:inbox and tag:social" :key "3")
        (:name "Updates" :query "path:personal/** and tag:inbox and tag:updates" :key "4")
        (:name "Forums" :query "path:personal/** and tag:inbox and tag:forums" :key "5")
        (:name "Inbox" :query "tag:inbox" :key "i")
        (:name "Work inbox" :query "path:work/** and tag:inbox" :key "w")
        (:name "Unread" :query "tag:unread" :key "u")
        (:name "All mail" :query "*" :key "a")
        (:name "Unsubscribe" :query "path:personal/** and tag:Unsubscribe" :key "x")
        (:name "Unsubscribe Success" :query "path:personal/** and tag:\"Unsubscribe Success\"")
        (:name "Unsubscribe Failed" :query "path:personal/** and tag:\"Unsubscribe Failed\"")))

(defun sysinit-mail-send-account ()
  "Select the Lieer account from the composed From header."
  (let* ((from (cadr (mail-extract-address-components (message-field-value "From"))))
         (account (assoc-string from sysinit-mail-accounts t)))
    (unless account (user-error "No configured mail account for %s" from))
    (setq-local message-sendmail-extra-arguments
                (list "send" "--quiet" "--path" (cadr account)))))
(add-hook 'message-send-mail-hook #'sysinit-mail-send-account)
(add-hook 'message-mode-hook #'evil-insert-state)

(defvar sysinit-mail-sync-pending nil)

(defun sysinit-mail-sync ()
  "Synchronize signed-in accounts without blocking the mail view."
  (interactive)
  (if (process-live-p (get-process "mail-sync"))
      (setq sysinit-mail-sync-pending t)
    (setq sysinit-mail-sync-pending nil)
    (make-process
     :name "mail-sync" :buffer "*mail-sync*"
     :command (list sysinit-mail-sync-command) :noquery t
     :sentinel (lambda (process _event)
                 (when (memq (process-status process) '(exit signal))
                   (if (= (process-exit-status process) 0)
                       (progn (notmuch-refresh-all-buffers)
                              (message "Mail synchronized")
                              (when sysinit-mail-sync-pending (sysinit-mail-sync)))
                     (message "Mail sync failed; see *mail-sync* (run mail-auth personal to sign in)")))))))

(defun sysinit-mail-tag (changes)
  "Apply CHANGES to selected messages, restricted to the current search."
  (cond
   ((derived-mode-p 'notmuch-search-mode)
    (notmuch-search-tag changes nil nil t))
   ((derived-mode-p 'notmuch-show-mode)
    (notmuch-show-tag-message changes))
   (t (user-error "Open a mail view first")))
  (when (evil-visual-state-p) (evil-exit-visual-state))
  (sysinit-mail-sync))

(defun sysinit-mail-read ()
  "Mark the current selection read."
  (interactive)
  (sysinit-mail-tag '("-unread")))
(defun sysinit-mail-unread ()
  "Mark the current selection unread."
  (interactive)
  (sysinit-mail-tag '("+unread")))
(defun sysinit-mail-archive ()
  "Archive the current selection without changing its read status."
  (interactive)
  (sysinit-mail-tag '("-inbox")))
(defun sysinit-mail-unsubscribe ()
  "Apply the existing Unsubscribe label; leave processing to Gmail automation."
  (interactive)
  (sysinit-mail-tag '("+Unsubscribe")))
(defun sysinit-mail-select-all ()
  "Select every result in this view."
  (interactive)
  (goto-char (point-min))
  (evil-visual-line)
  (goto-char (point-max)))
(defun sysinit-mail-view (key)
  "Open the saved mail view identified by KEY."
  (let ((view (cl-find key notmuch-saved-searches
                       :key (lambda (entry) (plist-get entry :key)) :test #'equal)))
    (notmuch-search (plist-get view :query))))
(defun sysinit-mail-help ()
  "Show the mail client's keyboard controls."
  (interactive)
  (with-help-window "*Mail keys*"
    (princ "Mail\n\n1–5: Gmail categories   gi: Inbox   ga: All mail\nj/k: move   Enter: open   q: back   s: search   G: sync\nV then j/k: select rows   ,v: select all results\n,r: mark read   ,u: mark unread   e: archive   ,U: Unsubscribe label\nc: compose   r: reply   R: reply all   f: forward\nCompose: i: insert   Escape: normal   C-c C-c: send   C-c C-k: cancel\nQ: quit Emacs   ?: this help\n\nChanges sync after each action. G fetches new mail.\nFirst login: run mail-auth personal in your shell.\n")))

(dolist (mode '(notmuch-hello-mode notmuch-search-mode notmuch-show-mode))
  (evil-set-initial-state mode 'normal))
(dolist (map (list notmuch-hello-mode-map notmuch-search-mode-map notmuch-show-mode-map))
  (evil-define-key 'normal map
    (kbd "j") #'next-line (kbd "k") #'previous-line
    (kbd "q") #'notmuch-bury-or-kill-this-buffer
    (kbd "Q") #'save-buffers-kill-emacs
    (kbd "s") #'notmuch-search (kbd "G") #'sysinit-mail-sync
    (kbd "c") #'notmuch-mua-new-mail (kbd "?") #'sysinit-mail-help)
  (dolist (key '("1" "2" "3" "4" "5" "i" "a" "u" "x" "w"))
    (let ((view-key key))
      (evil-define-key 'normal map (kbd (concat "g" key))
        (lambda () (interactive) (sysinit-mail-view view-key)))))
  (dolist (key '("1" "2" "3" "4" "5"))
    (let ((view-key key))
      (evil-define-key 'normal map (kbd key)
        (lambda () (interactive) (sysinit-mail-view view-key))))))
(evil-define-key 'normal notmuch-hello-mode-map
  (kbd "RET") #'widget-button-press
  (kbd "TAB") #'widget-forward)
(evil-define-key 'normal notmuch-search-mode-map
  (kbd "j") #'notmuch-search-next-thread
  (kbd "k") #'notmuch-search-previous-thread
  (kbd "RET") #'notmuch-search-show-thread
  (kbd ",v") #'sysinit-mail-select-all
  (kbd "r") #'notmuch-search-reply-to-thread-sender
  (kbd "R") #'notmuch-search-reply-to-thread)
(dolist (state '(normal visual))
  (evil-define-key state notmuch-search-mode-map
    (kbd ",r") #'sysinit-mail-read (kbd ",u") #'sysinit-mail-unread
    (kbd "e") #'sysinit-mail-archive (kbd ",U") #'sysinit-mail-unsubscribe))
(evil-define-key 'normal notmuch-show-mode-map
  (kbd ",r") #'sysinit-mail-read (kbd ",u") #'sysinit-mail-unread
  (kbd "e") #'sysinit-mail-archive (kbd ",U") #'sysinit-mail-unsubscribe
  (kbd "r") #'notmuch-show-reply-sender (kbd "R") #'notmuch-show-reply
  (kbd "f") #'notmuch-show-forward-message)
(setq notmuch-hello-sections
      '(notmuch-hello-insert-header notmuch-hello-insert-saved-searches
        notmuch-hello-insert-search notmuch-hello-insert-recent-searches))
(add-hook 'notmuch-hello-mode-hook
          (lambda () (setq-local header-line-format " Mail   1–5 Categories   gi Inbox   G Sync   c Compose   ? Help")))

(defun sysinit-mail-sync-if-authenticated ()
  "Refresh mail only after an account has completed browser login."
  (when (cl-some (lambda (account)
                   (file-exists-p (expand-file-name ".credentials.gmailieer.json" (cadr account))))
                 sysinit-mail-accounts)
    (sysinit-mail-sync)))
(unless noninteractive
  (run-at-time 1 300 #'sysinit-mail-sync-if-authenticated))
