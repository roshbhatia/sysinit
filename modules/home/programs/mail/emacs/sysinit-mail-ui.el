;;; sysinit-mail-ui.el --- Mail ui -*- lexical-binding: t; -*-

(require 'which-key)
(require 'vertico)
(require 'orderless)
(require 'marginalia)
(setq which-key-idle-delay 0.35
      which-key-side-window-max-height 0.35
      which-key-max-description-length 32
      vertico-count 10
      vertico-resize t
      completion-styles '(orderless basic)
      completion-category-defaults nil
      completion-category-overrides '((file (styles partial-completion basic)))
      resize-mini-windows t
      max-mini-window-height 0.35
      window-combination-resize t
      frame-resize-pixelwise t
      split-width-threshold 140
      split-height-threshold 24)
(require 'base16-theme)
(deftheme sysinit-mail "Shared sysinit palette.")
(defvar sysinit-mail-palette nil)
(setq base16-theme-256-color-source 'colors
      base16-distinct-fringe-background nil
      base16-highlight-mode-line nil)
(base16-theme-define
 'sysinit-mail
 (apply #'append (mapcar (lambda (entry)
                          (list (intern (concat ":" (symbol-name (car entry)))) (cdr entry)))
                        sysinit-mail-palette)))
(enable-theme 'sysinit-mail)
(which-key-mode 1)
(vertico-mode 1)
(marginalia-mode 1)
(which-key-setup-side-window-bottom)

(defun sysinit-mail-terminal-background (&optional frame)
  "Use the terminal background so WezTerm controls opacity."
  (let ((frame (or frame (selected-frame))))
    (unless (display-graphic-p frame)
      (dolist (face '(default fringe notmuch-search-matching-authors
                     notmuch-search-non-matching-authors notmuch-show-summary))
        (when (facep face) (set-face-background face "unspecified-bg" frame))))))
(sysinit-mail-terminal-background)
(add-hook 'after-make-frame-functions #'sysinit-mail-terminal-background)

(define-key vertico-map (kbd "C-j") #'vertico-next)
(define-key vertico-map (kbd "C-k") #'vertico-previous)
(dolist (map (list minibuffer-local-map minibuffer-local-completion-map
                  minibuffer-local-must-match-map))
  (define-key map (kbd "<escape>") #'abort-recursive-edit))

(setq-default mode-line-format
              '((:eval (if (bound-and-true-p evil-local-mode)
                           (format " %s " (upcase (symbol-name evil-state))) " "))
                "  %l:%c  " mode-line-process))
(setq notmuch-tag-formats
      '(("unread" (propertize "\uf0e0" 'face 'notmuch-tag-unread))
        ("flagged" "\uf005")
        ("inbox" "\uf01c")
        ("personal" "Primary")
        ("promotions" "\uf02b Promotions")
        ("social" "\uf0c0 Social")
        ("updates" "\uf021 Updates")
        ("forums" "\uf086 Forums")))
(setq notmuch-search-result-format
      '(("date" . "%12s  ") ("count" . "%-7s ") ("authors" . "%-22s  ")
        ("subject" . "%s ") ("tags" . "(%s)")))
(setq notmuch-hello-sections '(notmuch-hello-insert-saved-searches))
(dolist (hook '(notmuch-hello-mode-hook notmuch-search-mode-hook notmuch-show-mode-hook notmuch-show-hook notmuch-tree-mode-hook))
  (add-hook hook #'sysinit-mail-header))

(provide 'sysinit-mail-ui)
