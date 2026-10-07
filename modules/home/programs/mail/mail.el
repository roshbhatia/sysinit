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
  "Show the selected account and account switch shortcut."
  (setq-local header-line-format
              (format " %s   SPC a Accounts   SPC c Categories   SPC m s Sync"
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

(defun sysinit-mail-refresh-buffers (&optional buffers)
  "Refresh idle mail buffers and defer searches that are still loading."
  (let (pending)
    (dolist (buffer (or buffers (buffer-list)))
      (when (buffer-live-p buffer)
        (with-current-buffer buffer
          (when (derived-mode-p 'notmuch-search-mode 'notmuch-tree-mode
                                'notmuch-show-mode 'notmuch-hello-mode)
            (if (get-buffer-process buffer)
                (push buffer pending)
              (notmuch-refresh-this-buffer))))))
    (when pending
      (run-at-time 0.25 nil #'sysinit-mail-refresh-buffers pending))))

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
                       (progn (sysinit-mail-refresh-buffers)
                              (message "Mail synchronized")
                              (when sysinit-mail-sync-pending (sysinit-mail-sync)))
                     (message "Mail sync failed; see *mail-sync* (run mail-auth personal to sign in)")))))))

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
    (let* ((query (plist-get view :query))
           (loading (cl-find-if
                     (lambda (buffer)
                       (with-current-buffer buffer
                         (and (eq major-mode 'notmuch-search-mode)
                              (equal notmuch-search-query-string query)
                              (get-buffer-process buffer))))
                     (buffer-list))))
      (if loading (pop-to-buffer loading) (notmuch-search query)))))
(defun sysinit-mail-open ()
  "Open the selected account's Primary inbox."
  (interactive)
  (sysinit-mail-view "1"))

(defun sysinit-mail-help ()
  "Show the mail client's keyboard controls."
  (interactive)
  (with-help-window "*Mail keys*"
    (princ "Mail — one account at a time\n\nSPC a: switch account   gi: Inbox   ga: All mail   gu: Unread\nSPC cA: all inbox categories   SPC cp: Primary (default)\nSPC cr: Promotions   SPC cs: Social   SPC cu: Updates\nSPC f g / s: search this account\nj/k: move   Enter: open   q: back   gg/G: first/last\nC-u/C-d: half page   / n N: find in view   SPC f b: buffers\nV then j/k: select rows   ,v: select all results\n,r: mark read   ,u: mark unread   e: archive   ,U: Unsubscribe label\nc: compose   r: reply   R: reply all   f: forward\nSPC v t: thread tree   Enter: preview   Tab: fold\nSPC m i: attached image via Chafa\nSPC m s: sync   SPC m l: sync log   SPC ?: help   Q: quit\nCompose: i: insert   Escape: normal   C-c C-c: send   C-c C-k: cancel\n\nAutosync runs at startup, every minute, and after mail actions.\nAccount switching opens Primary and preserves drafts.\n")))

(defun sysinit-mail-sync-log ()
  "Open the latest sync output."
  (interactive)
  (pop-to-buffer (get-buffer-create "*mail-sync*")))


(dolist (mode '(notmuch-hello-mode notmuch-search-mode notmuch-show-mode notmuch-tree-mode))
  (evil-set-initial-state mode 'normal))
(dolist (map (list notmuch-hello-mode-map notmuch-search-mode-map notmuch-show-mode-map notmuch-tree-mode-map))
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
    (kbd "SPC v t") #'sysinit-mail-tree
    (kbd "SPC m i") #'sysinit-mail-preview-image
    (kbd "SPC ?") #'sysinit-mail-help
    (kbd "C-h") #'windmove-left (kbd "C-j") #'windmove-down
    (kbd "C-k") #'windmove-up (kbd "C-l") #'windmove-right)
  (dolist (entry '(("A" . "i") ("p" . "1") ("r" . "2") ("s" . "3") ("u" . "4")))
    (let ((view-key (cdr entry)))
      (evil-define-key* 'normal map (kbd (concat "SPC c" (car entry)))
        (lambda () (interactive) (sysinit-mail-view view-key)))))
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
(dolist (hook '(notmuch-hello-mode-hook notmuch-search-mode-hook notmuch-show-mode-hook notmuch-show-hook notmuch-tree-mode-hook))
  (add-hook hook #'sysinit-mail-header))

(defun sysinit-mail-sync-if-authenticated ()
  "Refresh mail only after an account has completed browser login."
  (when (cl-some (lambda (account)
                   (file-exists-p (expand-file-name ".credentials.gmailieer.json" (cadr account))))
                 sysinit-mail-accounts)
    (sysinit-mail-sync)))
(defvar sysinit-mail-sync-timer nil)
(defun sysinit-mail-start-autosync ()
  "Maintain one timer for startup and one-minute mail synchronization."
  (when (timerp sysinit-mail-sync-timer)
    (cancel-timer sysinit-mail-sync-timer))
  (setq sysinit-mail-sync-timer
        (run-at-time 1 60 #'sysinit-mail-sync-if-authenticated)))
(unless noninteractive
  (sysinit-mail-start-autosync))

(defun sysinit-mail-tree ()
  "Open the current query as a thread tree with an optional message preview."
  (interactive)
  (notmuch-tree (if (derived-mode-p 'notmuch-search-mode)
                    notmuch-search-query-string
                  (sysinit-mail-scope "tag:inbox"))))

(defun sysinit-mail-tree-matching (original tree depth status first last)
  "Keep messages outside the account or category out of thread trees."
  (if (plist-get (car tree) :match)
      (funcall original tree depth status first last)
    (notmuch-tree-insert-thread (cadr tree) depth status)))
(advice-add 'notmuch-tree-insert-tree :around #'sysinit-mail-tree-matching)

(evil-define-key* 'normal notmuch-tree-mode-map
  (kbd "j") #'notmuch-tree-next-message (kbd "k") #'notmuch-tree-prev-message
  (kbd "RET") #'notmuch-tree-show-message
  (kbd "TAB") #'outline-toggle-children
  (kbd ",v") #'sysinit-mail-select-all
  (kbd "r") #'notmuch-tree-reply-sender (kbd "R") #'notmuch-tree-reply)
(dolist (state '(normal visual))
  (evil-define-key* state notmuch-tree-mode-map
    (kbd ",r") #'sysinit-mail-read (kbd ",u") #'sysinit-mail-unread
    (kbd "e") #'sysinit-mail-archive (kbd ",U") #'sysinit-mail-unsubscribe))

(defun sysinit-mail-image-parts (parts)
  "Collect locally attached images from nested MIME parts."
  (cl-mapcan (lambda (part)
               (let ((type (plist-get part :content-type)))
                 (cond ((string-prefix-p "image/" (or type "")) (list part))
                       ((string-prefix-p "multipart/" (or type ""))
                        (sysinit-mail-image-parts (plist-get part :content))))))
             parts))

(defun sysinit-mail-preview-image ()
  "Preview an attached image with Chafa in WezTerm or an Emacs text buffer."
  (interactive)
  (unless (derived-mode-p 'notmuch-show-mode)
    (user-error "Open a message first, then press SPC m i"))
  (let* ((msg (notmuch-show-get-message-properties))
         (parts (sysinit-mail-image-parts (plist-get msg :body)))
         (choices (mapcar (lambda (part)
                           (cons (format "%s: %s" (plist-get part :id)
                                         (or (plist-get part :filename)
                                             (plist-get part :content-type))) part)) parts)))
    (unless choices (user-error "This message has no attached images"))
    (let* ((part (if (= (length choices) 1) (cdar choices)
                   (cdr (assoc (completing-read "Image: " choices nil t) choices))))
           (file (make-temp-file "email-image-" nil ".image"))
           (handed-off nil))
      (unwind-protect
          (progn
            (let ((coding-system-for-write 'no-conversion))
              (write-region (notmuch-get-bodypart-binary msg part notmuch-show-process-crypto)
                            nil file nil 'silent))
            (if (and (getenv "WEZTERM_PANE") (executable-find "wezterm"))
                (progn
                  (unless (= 0 (call-process "wezterm" nil "*mail-image-log*" nil
                                             "cli" "--no-auto-start" "split-pane"
                                             "--right" "--percent" "40" "--"
                                             sysinit-mail-image-command file))
                    (error "WezTerm preview failed; see *mail-image-log*"))
                  (setq handed-off t))
              (with-current-buffer (get-buffer-create "*Mail image*")
                (let ((inhibit-read-only t))
                  (erase-buffer)
                  (unless (= 0 (call-process sysinit-mail-chafa-command nil t nil
                                            "--format=symbols" "--colors=full"
                                            "--animate=off" "--size=80x30" "--" file))
                    (error "Chafa could not render this image"))
                  (ansi-color-apply-on-region (point-min) (point-max)))
                (special-mode)
                (pop-to-buffer (current-buffer)))))
        (unless handed-off (delete-file file))))))
