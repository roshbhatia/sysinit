;;; sysinit-mail-keys.el --- Mail keys -*- lexical-binding: t; -*-

(dolist (mode '(notmuch-hello-mode notmuch-search-mode notmuch-show-mode notmuch-tree-mode))
  (evil-set-initial-state mode 'normal))
(dolist (map (list notmuch-hello-mode-map notmuch-search-mode-map notmuch-show-mode-map notmuch-tree-mode-map))
  (evil-define-key* 'normal map
    (kbd "j") #'next-line (kbd "k") #'previous-line
    (kbd "q") #'notmuch-bury-or-kill-this-buffer
    (kbd "Q") #'save-buffers-kill-emacs
    (kbd "s") #'sysinit-mail-search
    (kbd "<escape>") #'sysinit-mail-clear-search
    (kbd "SPC") nil
    (kbd "c") #'notmuch-mua-new-mail
    (kbd "C-h") #'windmove-left (kbd "C-j") #'windmove-down
    (kbd "C-k") #'windmove-up (kbd "C-l") #'windmove-right)
  (dolist (key '("1" "2" "3" "4" "5" "i" "a" "u" "x"))
    (let ((view-key key))
      (evil-define-key* 'normal map (kbd (concat "g" key))
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

(defun sysinit-mail-reply ()
  "Reply to the selected sender in a list, tree, or message."
  (interactive)
  (call-interactively (cond ((derived-mode-p 'notmuch-search-mode) #'notmuch-search-reply-to-thread-sender)
                          ((derived-mode-p 'notmuch-tree-mode) #'notmuch-tree-reply-sender)
                          (t #'notmuch-show-reply-sender))))

(defun sysinit-mail-reply-all ()
  "Reply to all recipients in the selected conversation."
  (interactive)
  (call-interactively (cond ((derived-mode-p 'notmuch-search-mode) #'notmuch-search-reply-to-thread)
                          ((derived-mode-p 'notmuch-tree-mode) #'notmuch-tree-reply)
                          (t #'notmuch-show-reply))))

(defun sysinit-mail-edit-tags ()
  "Edit labels on the selected messages and sync the changes."
  (interactive)
  (sysinit-mail-tag (notmuch-read-tag-changes nil "Labels (+add/-remove): ")))

(defvar sysinit-mail-leader-actions
  '(("SPC" "Command palette" execute-extended-command)
    ("a" "Switch account" sysinit-mail-switch-account)
    ("c A" "All inbox categories" (:view "i"))
    ("c p" "Primary" (:view "1"))
    ("c r" "Promotions" (:view "2"))
    ("c s" "Social" (:view "3"))
    ("c u" "Updates" (:view "4"))
    ("c f" "Forums" (:view "5"))
    ("f g" "Search account" sysinit-mail-search)
    ("f c" "Clear search" sysinit-mail-clear-search)
    ("f b" "Switch buffer" switch-to-buffer)
    ("m c" "Compose" notmuch-mua-new-mail)
    ("m r" "Reply to sender" sysinit-mail-reply)
    ("m A" "Reply to all" sysinit-mail-reply-all)
    ("m a" "Archive selection" sysinit-mail-archive)
    ("m R" "Mark read" sysinit-mail-read)
    ("m u" "Mark unread" sysinit-mail-unread)
    ("m U" "Unsubscribe label" sysinit-mail-unsubscribe)
    ("m t" "Edit labels" sysinit-mail-edit-tags)
    ("m v" "Select all results" sysinit-mail-select-all)
    ("m s" "Sync now" sysinit-mail-sync)
    ("m l" "Sync log" sysinit-mail-sync-log)
    ("m i" "Image preview" sysinit-mail-preview-image)
    ("v t" "Thread tree" sysinit-mail-tree)
    ("v l" "Thread list" sysinit-mail-list)
    ("v a" "All mail including archive" (:view "a"))
    ("v u" "Unread" (:view "u"))
    ("w" "Close view" notmuch-bury-or-kill-this-buffer)
    ("q q" "Quit mail" save-buffers-kill-emacs)
    ("?" "Keyboard help" sysinit-mail-help)))

(dolist (map (list notmuch-hello-mode-map notmuch-search-mode-map
                   notmuch-show-mode-map notmuch-tree-mode-map))
  (dolist (entry sysinit-mail-leader-actions)
    (let* ((key (concat "SPC " (car entry)))
           (action (nth 2 entry))
           (command (if (and (listp action) (eq (car action) :view))
                        (let ((view (cadr action)))
                          (lambda () (interactive) (sysinit-mail-view view)))
                      action)))
      (evil-define-key* 'normal map (kbd key) command)
      (which-key-add-key-based-replacements key (nth 1 entry)))))
(which-key-add-key-based-replacements
  "SPC c" "Categories" "SPC f" "Find" "SPC m" "Mail"
  "SPC v" "Views" "SPC q" "Quit")

(defun sysinit-mail-help ()
  "List leader actions from the same registry that installs the menus."
  (interactive)
  (with-help-window "*Mail keys*"
    (princ "Space opens menus. Escape clears search or cancels a picker.\n\n")
    (dolist (entry sysinit-mail-leader-actions)
      (princ (format "SPC %-7s %s\n" (car entry) (nth 1 entry))))
    (princ "\nV selects rows; ,r read; ,u unread; e archive.\ngg/G and counts use Vim navigation. q returns; Ctrl-h/j/k/l moves between windows.\n")))

(provide 'sysinit-mail-keys)
