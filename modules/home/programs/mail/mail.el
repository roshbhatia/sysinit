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
      notmuch-show-only-matching-messages t
      notmuch-always-prompt-for-sender nil)

(defvar sysinit-mail-account
  (or (cl-find (getenv "EMAIL_ACCOUNT") sysinit-mail-accounts :key #'caddr :test #'equal)
      (car sysinit-mail-accounts)))
(defvar sysinit-mail-state-file nil)
(defvar sysinit-mail-view-definitions
  '((:name "Inbox" :query "tag:inbox" :key "i")
    (:name "Unread" :query "tag:unread" :key "u")
    (:name "All mail" :query "*" :key "a")
    (:name "Primary" :query "tag:inbox and tag:personal" :key "1")
    (:name "Promotions" :query "tag:inbox and tag:promotions" :key "2")
    (:name "Social" :query "tag:inbox and tag:social" :key "3")
    (:name "Updates" :query "tag:inbox and tag:updates" :key "4")
    (:name "Forums" :query "tag:inbox and tag:forums" :key "5")
    (:name "Unsubscribe" :query "tag:Unsubscribe" :key "x")
    (:name "Unsubscribe Success" :query "tag:\"Unsubscribe Success\"")
    (:name "Unsubscribe Failed" :query "tag:\"Unsubscribe Failed\"")))

(defun sysinit-mail-scope (query)
  "Restrict QUERY to the selected account's mail directory."
  (let ((scope (concat "path:" (file-name-nondirectory
                               (directory-file-name (cadr sysinit-mail-account))) "/**")))
    (if (string-prefix-p (concat scope " and (") query) query
      (format "%s and (%s)" scope query))))

(defun sysinit-mail-scoped-search (args)
  "Keep native searches and dashboard searches inside the selected account."
  (cons (sysinit-mail-scope (or (car args) "*")) (cdr args)))
(advice-add 'notmuch-search :filter-args #'sysinit-mail-scoped-search)

(defun sysinit-mail-configure-account ()
  "Set views and sender identity for the selected account."
  (setq user-mail-address (car sysinit-mail-account)
        notmuch-identities (list (car sysinit-mail-account))
        notmuch-saved-searches
        (mapcar (lambda (view)
                  (plist-put (copy-sequence view) :query
                             (sysinit-mail-scope (plist-get view :query))))
                sysinit-mail-view-definitions))
  (when sysinit-mail-state-file
    (make-directory (file-name-directory sysinit-mail-state-file) t)
    (let ((temporary (make-temp-file (concat sysinit-mail-state-file "."))))
      (unwind-protect
          (progn
            (with-temp-file temporary (insert (caddr sysinit-mail-account)))
            (set-file-modes temporary #o600)
            (rename-file temporary sysinit-mail-state-file t))
        (when (file-exists-p temporary) (delete-file temporary))))))
(sysinit-mail-configure-account)

(defun sysinit-mail-switch-account ()
  "Select one account and close mail views from the previous account."
  (interactive)
  (let* ((address (completing-read "Mail account: " (mapcar #'car sysinit-mail-accounts)
                                   nil t nil nil (car sysinit-mail-account)))
         (account (assoc-string address sysinit-mail-accounts t)))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (derived-mode-p 'notmuch-hello-mode 'notmuch-search-mode
                              'notmuch-show-mode 'notmuch-tree-mode)
          (kill-buffer buffer))))
    (setq sysinit-mail-account account
          notmuch-search-history nil)
    (sysinit-mail-configure-account)
    (notmuch)))

(defun sysinit-mail-header ()
  "Show the selected account and account switch shortcut."
  (setq-local header-line-format
              (format " %s   SPC a Accounts   gi Inbox   SPC m s Sync   SPC ? Help"
                      (car sysinit-mail-account))))

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
    (unless view (user-error "Unknown mail view: %s" key))
    (notmuch-search (plist-get view :query))))
(defun sysinit-mail-help ()
  "Show the mail client's keyboard controls."
  (interactive)
  (with-help-window "*Mail keys*"
    (princ "Mail — one account at a time\n\nSPC a: switch account   gi: Inbox   ga: All mail   gu: Unread\n1–5: Gmail categories   SPC f g / s: search this account\nj/k: move   Enter: open   q: back   gg/G: first/last\nC-u/C-d: half page   / n N: find in view   SPC f b: buffers\nV then j/k: select rows   ,v: select all results\n,r: mark read   ,u: mark unread   e: archive   ,U: Unsubscribe label\nc: compose   r: reply   R: reply all   f: forward\nSPC m s: sync   SPC m l: sync log   SPC ?: help   Q: quit\nCompose: i: insert   Escape: normal   C-c C-c: send   C-c C-k: cancel\n\nAccount switching closes old mail views and preserves drafts.\n")))

(defun sysinit-mail-sync-log ()
  "Open the latest sync output."
  (interactive)
  (pop-to-buffer (get-buffer-create "*mail-sync*")))


(dolist (mode '(notmuch-hello-mode notmuch-search-mode notmuch-show-mode))
  (evil-set-initial-state mode 'normal))
(dolist (map (list notmuch-hello-mode-map notmuch-search-mode-map notmuch-show-mode-map))
  (evil-define-key* 'normal map
    (kbd "j") #'next-line (kbd "k") #'previous-line
    (kbd "q") #'notmuch-bury-or-kill-this-buffer
    (kbd "Q") #'save-buffers-kill-emacs
    (kbd "s") #'notmuch-search
    (kbd "SPC") nil
    (kbd "c") #'notmuch-mua-new-mail
    (kbd "SPC a") #'sysinit-mail-switch-account
    (kbd "SPC f g") #'notmuch-search
    (kbd "SPC f b") #'switch-to-buffer
    (kbd "SPC m s") #'sysinit-mail-sync
    (kbd "SPC m l") #'sysinit-mail-sync-log
    (kbd "SPC ?") #'sysinit-mail-help
    (kbd "C-h") #'windmove-left (kbd "C-j") #'windmove-down
    (kbd "C-k") #'windmove-up (kbd "C-l") #'windmove-right)
  (dolist (key '("1" "2" "3" "4" "5" "i" "a" "u" "x"))
    (let ((view-key key))
      (evil-define-key* 'normal map (kbd (concat "g" key))
        (lambda () (interactive) (sysinit-mail-view view-key)))))
  (dolist (key '("1" "2" "3" "4" "5"))
    (let ((view-key key))
      (evil-define-key* 'normal map (kbd key)
        (lambda () (interactive) (sysinit-mail-view view-key))))))
(evil-define-key* 'normal notmuch-hello-mode-map
  (kbd "RET") #'widget-button-press
  (kbd "TAB") #'widget-forward)
(evil-define-key* 'normal notmuch-search-mode-map
  (kbd "j") #'notmuch-search-next-thread
  (kbd "k") #'notmuch-search-previous-thread
  (kbd "RET") #'notmuch-search-show-thread
  (kbd ",v") #'sysinit-mail-select-all
  (kbd "r") #'notmuch-search-reply-to-thread-sender
  (kbd "R") #'notmuch-search-reply-to-thread)
(dolist (state '(normal visual))
  (evil-define-key* state notmuch-search-mode-map
    (kbd ",r") #'sysinit-mail-read (kbd ",u") #'sysinit-mail-unread
    (kbd "e") #'sysinit-mail-archive (kbd ",U") #'sysinit-mail-unsubscribe))
(evil-define-key* 'normal notmuch-show-mode-map
  (kbd ",r") #'sysinit-mail-read (kbd ",u") #'sysinit-mail-unread
  (kbd "e") #'sysinit-mail-archive (kbd ",U") #'sysinit-mail-unsubscribe
  (kbd "r") #'notmuch-show-reply-sender (kbd "R") #'notmuch-show-reply
  (kbd "f") #'notmuch-show-forward-message)
(setq notmuch-hello-sections '(notmuch-hello-insert-saved-searches))
(dolist (hook '(notmuch-hello-mode-hook notmuch-search-mode-hook notmuch-show-mode-hook notmuch-show-hook))
  (add-hook hook #'sysinit-mail-header))

(defun sysinit-mail-sync-if-authenticated ()
  "Refresh mail only after an account has completed browser login."
  (when (cl-some (lambda (account)
                   (file-exists-p (expand-file-name ".credentials.gmailieer.json" (cadr account))))
                 sysinit-mail-accounts)
    (sysinit-mail-sync)))
(unless noninteractive
  (run-at-time 1 300 #'sysinit-mail-sync-if-authenticated))
