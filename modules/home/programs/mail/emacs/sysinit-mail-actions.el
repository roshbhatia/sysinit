;;; sysinit-mail-actions.el --- Mail actions -*- lexical-binding: t; -*-

(defun sysinit-mail-send-account ()
  "Select the Lieer account from the composed From header."
  (let* ((from (cadr (mail-extract-address-components (message-field-value "From"))))
         (account (assoc-string from sysinit-mail-accounts t)))
    (unless account (user-error "No configured mail account for %s" from))
    (setq-local message-sendmail-extra-arguments
                (list "send" "--quiet" "--path" (cadr account)))))
(add-hook 'message-send-mail-hook #'sysinit-mail-send-account)
(add-hook 'message-mode-hook #'evil-insert-state)
(defun sysinit-mail-tag (changes)
  "Apply CHANGES to selected messages, restricted to the current search."
  (cond
   ((derived-mode-p 'notmuch-search-mode)
    (notmuch-search-tag changes nil nil t))
   ((derived-mode-p 'notmuch-tree-mode)
    (let ((end (copy-marker (if (use-region-p) (region-end) (line-end-position))))
          (start (if (use-region-p) (region-beginning) (line-beginning-position))))
      (save-excursion
        (goto-char start)
        (while (< (point) end)
          (when (notmuch-tree-get-message-id) (notmuch-tree-tag changes))
          (forward-line 1)))
      (set-marker end nil)))
   ((derived-mode-p 'notmuch-show-mode)
    (notmuch-show-tag-message changes))
   (t (user-error "Open a mail view first")))
  (when (evil-visual-state-p) (evil-exit-visual-state))
  (sysinit-mail-refresh-buffers (list (current-buffer)))
  (sysinit-mail-sync))

(defun sysinit-mail-read ()
  "Mark the current selection read."
  (interactive)
  (sysinit-mail-tag '("-unread")))
(defun sysinit-mail-unread ()
  "Mark the current selection unread."
  (interactive)
  (sysinit-mail-tag '("+unread")))
(defun sysinit-mail-toggle-read ()
  "Mark the selection read if any matched message is unread, else unread."
  (interactive)
  (let ((query
         (cond
          ((derived-mode-p 'notmuch-search-mode)
           (pcase-let ((`(,beg ,end) (notmuch-interactive-region)))
             (notmuch-search-find-stable-query-region beg end t)))
          ((derived-mode-p 'notmuch-tree-mode)
           (let ((end (if (use-region-p) (region-end) (line-end-position))) ids)
             (save-excursion
               (when (use-region-p) (goto-char (region-beginning)))
               (while (< (point) end)
                 (when-let* ((id (notmuch-tree-get-message-id))) (push id ids))
                 (forward-line 1)))
             (unless ids (user-error "No messages selected"))
             (mapconcat #'identity ids " or ")))
          ((derived-mode-p 'notmuch-show-mode) (notmuch-show-get-message-id))
          (t (user-error "Open a mail view first")))))
    (sysinit-mail-tag
     (if (> (notmuch-call-notmuch-sexp "count" (concat "tag:unread and (" query ")")) 0)
         '("-unread") '("+unread")))))

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
  (unless (derived-mode-p 'notmuch-search-mode 'notmuch-tree-mode)
    (user-error "Open a message list or tree to select results"))
  (goto-char (point-min))
  (evil-visual-line)
  (goto-char (point-max)))

(provide 'sysinit-mail-actions)
