;;; sysinit-mail-accounts.el --- Mail accounts -*- lexical-binding: t; -*-

(defvar sysinit-mail-account
  (or (cl-find (getenv "EMAIL_ACCOUNT") sysinit-mail-accounts :key #'caddr :test #'equal)
      (car sysinit-mail-accounts)))
(defvar sysinit-mail-state-file nil)
(defvar sysinit-mail-view-definitions
  '((:icon "" :name "Inbox" :query "tag:inbox" :key "i")
    (:icon "" :name "Unread" :query "tag:unread" :key "u")
    (:icon "" :name "All mail" :query "*" :key "a")
    (:icon "" :name "Primary" :query "tag:inbox and tag:personal" :key "1")
    (:icon "" :name "Promotions" :query "tag:inbox and tag:promotions" :key "2")
    (:icon "" :name "Social" :query "tag:inbox and tag:social" :key "3")
    (:icon "" :name "Updates" :query "tag:inbox and tag:updates" :key "4")
    (:icon "" :name "Forums" :query "tag:inbox and tag:forums" :key "5")
    (:icon "" :name "Unsubscribe" :query "tag:Unsubscribe" :key "x")
    (:icon "" :name "Unsubscribe Success" :query "tag:\"Unsubscribe Success\"")
    (:icon "" :name "Unsubscribe Failed" :query "tag:\"Unsubscribe Failed\"")))

(defun sysinit-mail-scope (query)
  "Restrict QUERY to the selected account's mail directory."
  (let ((scope (concat "path:" (file-name-nondirectory
                               (directory-file-name (cadr sysinit-mail-account))) "/**")))
    (if (string-prefix-p (concat scope " and (") query) query
      (format "%s and (%s)" scope query))))

(defun sysinit-mail-scoped-search (args)
  "Keep native searches and dashboard searches inside the selected account."
  (cons (sysinit-mail-scope (or (car args) (notmuch-read-query "Search this account: "))) (cdr args)))
(advice-add 'notmuch-search :filter-args #'sysinit-mail-scoped-search)
(advice-add 'notmuch-tree :filter-args #'sysinit-mail-scoped-search)

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
    (sysinit-mail-open)))

(defun sysinit-mail-header ()
  "Show account and category without duplicating the message list labels."
  (setq-local header-line-format
              '(:eval
                (let ((view (cl-find sysinit-mail-current-view notmuch-saved-searches
                                     :key (lambda (v) (plist-get v :key)) :test #'equal)))
                  (format " %s   %s %s%s   ·   gi Inbox  SPC navigation  , actions"
                          (capitalize (caddr sysinit-mail-account))
                          (or (plist-get view :icon) "")
                          (or (plist-get view :name) "Mail")
                          (if sysinit-mail-filtered-p " / search" ""))))))

(provide 'sysinit-mail-accounts)
