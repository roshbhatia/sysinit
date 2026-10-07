;;; sysinit-mail-ui.el --- Mail ui -*- lexical-binding: t; -*-

(require 'which-key)
(require 'vertico)
(require 'orderless)
(require 'marginalia)
(require 'catppuccin-theme)
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
      split-height-threshold 24
      catppuccin-flavor (if (eq (frame-parameter nil 'background-mode) 'light) 'latte 'mocha))
(load-theme 'catppuccin t)
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

(setq notmuch-hello-sections '(notmuch-hello-insert-saved-searches))
(dolist (hook '(notmuch-hello-mode-hook notmuch-search-mode-hook notmuch-show-mode-hook notmuch-show-hook notmuch-tree-mode-hook))
  (add-hook hook #'sysinit-mail-header))

(provide 'sysinit-mail-ui)
