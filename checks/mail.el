;;; mail.el --- Mail integration checks -*- lexical-binding: t; -*-
(require 'ert)
(setq sysinit-mail-accounts '(("test@example.com" "/tmp/personal")
                              ("work@example.com" "/tmp/work"))
      sysinit-mail-sync-command (executable-find "true"))
(load (getenv "MAIL_CONFIG"))
;; Notmuch forces cwd to ~, which is absent in the Nix build sandbox.
(dolist (pair '((notmuch--make-process . make-process)
                (notmuch--call-process . call-process)
                (notmuch--call-process-region . call-process-region)
                (notmuch--process-lines . process-lines)))
  (advice-add (car pair) :override (cdr pair)))
(setq message-auto-save-directory temporary-file-directory)


(defun mail-test-command (&rest args)
  (with-temp-buffer
    (should (= 0 (apply #'call-process "notmuch" nil t nil args)))
    (string-trim (buffer-string))))

(defun mail-test-wait ()
  (let ((process (get-buffer-process (current-buffer))))
    (while (and process (process-live-p process))
      (accept-process-output process 0.1))))

(ert-deftest mail-category-bulk-actions ()
  (let* ((root (make-temp-file "mail-test-" t))
         (config (expand-file-name "config" root))
         (process-environment (copy-sequence process-environment)))
    (unwind-protect
        (progn
          (setenv "NOTMUCH_CONFIG" config)
          (with-temp-file config
            (insert (format "[database]\npath=%s/mail\n[user]\nname=Test\nprimary_email=test@example.com\n[new]\ntags=\n[maildir]\nsynchronize_flags=false\n" root)))
          (dolist (entry '(("one" "personal" "")
                           ("hidden" "personal" "In-Reply-To: <one@example.com>\nReferences: <one@example.com>\n")
                           ("two" "personal" "")
                           ("work" "work" "")))
            (let ((path (expand-file-name (format "mail/%s/mail/cur/%s" (nth 1 entry) (car entry)) root)))
              (make-directory (file-name-directory path) t)
              (with-temp-file path
                (insert (format "From: sender@example.com\nTo: test@example.com\nSubject: %s\nMessage-ID: <%s@example.com>\n%sDate: Wed, 7 Oct 2026 12:00:00 +0000\n\nTest message\n"
                                (if (equal (car entry) "hidden") "Re: one" (car entry))
                                (car entry) (nth 2 entry))))))
          (mail-test-command "new")
          (mail-test-command "tag" "+inbox" "+unread" "+personal" "--" "*")
          (mail-test-command "tag" "-personal" "+promotions" "--" "id:hidden@example.com")
          (sysinit-mail-view "1")
          (mail-test-wait)
          (should (eq evil-state 'normal))
          (should (eq (key-binding (kbd "j")) #'notmuch-search-next-thread))
          (should (eq (key-binding (kbd "e")) #'sysinit-mail-archive))
          (sysinit-mail-select-all)
          (sysinit-mail-read)
          (should (equal "2" (mail-test-command "count" "tag:unread")))
          (sysinit-mail-select-all)
          (sysinit-mail-unread)
          (should (equal "4" (mail-test-command "count" "tag:unread")))
          (sysinit-mail-select-all)
          (sysinit-mail-unsubscribe)
          (should (equal "2" (mail-test-command "count" "tag:Unsubscribe")))
          (sysinit-mail-select-all)
          (sysinit-mail-archive)
          (should (equal "2" (mail-test-command "count" "tag:inbox")))
          (should (equal "2" (mail-test-command "count" "tag:inbox and (id:hidden@example.com or id:work@example.com)")))
          (should (equal "4" (mail-test-command "count" "tag:unread")))
          (let ((process (get-process "mail-sync")))
            (when process (while (process-live-p process) (accept-process-output process 0.1)))))
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (when (derived-mode-p 'notmuch-search-mode) (kill-buffer buffer))))
      (delete-directory root t))))

(ert-deftest mail-sender-routing ()
  (with-temp-buffer
    (message-mode)
    (insert "From: Work User <work@example.com>\nTo: nobody@example.com\n\nDraft only")
    (sysinit-mail-send-account)
    (should (equal message-sendmail-extra-arguments '("send" "--quiet" "--path" "/tmp/work")))
    (erase-buffer)
    (insert "From: unknown@example.com\n\nDraft only")
    (should-error (sysinit-mail-send-account) :type 'user-error)))

(ert-deftest mail-category-label-names ()
  (should (equal (plist-get (cl-find "Unsubscribe Success" notmuch-saved-searches
                                   :key (lambda (entry) (plist-get entry :name)) :test #'equal) :query)
                 "path:personal/** and tag:\"Unsubscribe Success\"")))
