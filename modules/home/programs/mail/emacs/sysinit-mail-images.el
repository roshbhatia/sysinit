;;; sysinit-mail-images.el --- Mail images -*- lexical-binding: t; -*-

(require 'kitty-graphics)
(setq kitty-graphics-shr-scale 'fit
      kitty-graphics-shr-fit-width 0.85
      kitty-graphics-shr-fit-height 20)
(unless noninteractive (kitty-graphics-setup))

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

(provide 'sysinit-mail-images)
