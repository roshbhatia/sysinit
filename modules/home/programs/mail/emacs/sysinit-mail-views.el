;;; sysinit-mail-views.el --- Mail views -*- lexical-binding: t; -*-

(defvar-local sysinit-mail-current-view "1")
(defvar-local sysinit-mail-filtered-p nil)

(defun sysinit-mail-run-query (query)
  "Reuse a loading search instead of starting a second process in its buffer."
  (let* ((query (sysinit-mail-scope query))
         (loading (cl-find-if
                   (lambda (buffer)
                     (with-current-buffer buffer
                       (and (eq major-mode 'notmuch-search-mode)
                            (equal notmuch-search-query-string query)
                            (get-buffer-process buffer))))
                   (buffer-list))))
    (if loading (pop-to-buffer loading) (notmuch-search query))))

(defun sysinit-mail-view (key)
  "Open the saved mail view identified by KEY."
  (let ((view (cl-find key notmuch-saved-searches
                       :key (lambda (entry) (plist-get entry :key)) :test #'equal)))
    (unless view (user-error "Unknown mail view: %s" key))
    (sysinit-mail-run-query (plist-get view :query))
    (setq-local sysinit-mail-current-view key
                sysinit-mail-filtered-p nil)))

(defun sysinit-mail-open ()
  "Open the selected account's Primary inbox."
  (interactive)
  (sysinit-mail-view "1"))

(defun sysinit-mail-sync-log ()
  "Open the latest sync output."
  (interactive)
  (pop-to-buffer (get-buffer-create "*mail-sync*")))
(defun sysinit-mail-search (query)
  "Search the current account, or restore the category for an empty query."
  (interactive (list (notmuch-read-query "Search account: ")))
  (if (string-empty-p (string-trim query))
      (sysinit-mail-clear-search)
    (let ((view sysinit-mail-current-view))
      (sysinit-mail-run-query query)
      (setq-local sysinit-mail-current-view view
                  sysinit-mail-filtered-p t))))

(defun sysinit-mail-clear-search ()
  "Clear Vim highlights and restore the selected mail category."
  (interactive)
  (evil-ex-nohighlight)
  (when (fboundp 'evil-search-highlight-persist-remove-all)
    (evil-search-highlight-persist-remove-all))
  (when sysinit-mail-filtered-p
    (sysinit-mail-view sysinit-mail-current-view)))

(defun sysinit-mail-preserve-view (refresh &rest args)
  "Retain category and search state when notmuch refreshes its major mode."
  (let ((view sysinit-mail-current-view)
        (filtered sysinit-mail-filtered-p))
    (prog1 (apply refresh args)
      (setq-local sysinit-mail-current-view view
                  sysinit-mail-filtered-p filtered))))
(advice-add 'notmuch-refresh-this-buffer :around #'sysinit-mail-preserve-view)

(defun sysinit-mail-current-query ()
  "Return the current list or tree query."
  (cond ((derived-mode-p 'notmuch-search-mode) notmuch-search-query-string)
        ((derived-mode-p 'notmuch-tree-mode) (notmuch-tree-get-query))
        (t (sysinit-mail-scope "tag:inbox"))))

(defun sysinit-mail-tree ()
  "Open the current query as a thread tree with an optional message preview."
  (interactive)
  (let ((query (sysinit-mail-current-query))
        (filtered sysinit-mail-filtered-p)
        (view sysinit-mail-current-view))
    (notmuch-tree query)
    (setq-local sysinit-mail-current-view view
                sysinit-mail-filtered-p filtered)))

(defun sysinit-mail-list ()
  "Open the current tree query as a thread list."
  (interactive)
  (let ((query (sysinit-mail-current-query))
        (filtered sysinit-mail-filtered-p)
        (view sysinit-mail-current-view))
    (sysinit-mail-run-query query)
    (setq-local sysinit-mail-current-view view
                sysinit-mail-filtered-p filtered)))

(defun sysinit-mail-tree-matching (original tree depth status first last)
  "Keep messages outside the account or category out of thread trees."
  (if (plist-get (car tree) :match)
      (funcall original tree depth status first last)
    (notmuch-tree-insert-thread (cadr tree) depth status)))
(advice-add 'notmuch-tree-insert-tree :around #'sysinit-mail-tree-matching)

(provide 'sysinit-mail-views)
