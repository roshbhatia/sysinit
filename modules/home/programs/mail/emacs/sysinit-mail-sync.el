;;; sysinit-mail-sync.el --- Mail sync -*- lexical-binding: t; -*-

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
                   (pcase (process-exit-status process)
                     (0 (sysinit-mail-refresh-buffers)
                        (message "Mail synchronized")
                        (when sysinit-mail-sync-pending (sysinit-mail-sync)))
                     (75 (sysinit-mail-refresh-buffers)
                         (message "Mail sync already running; local views refreshed. Retry follows automatically."))
                     (_ (message "Mail sync failed; , l opens the error log"))))))))

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

(provide 'sysinit-mail-sync)
