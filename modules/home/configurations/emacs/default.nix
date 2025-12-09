{
  pkgs,
  ...
}:

{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs;

    extraPackages =
      epkgs: with epkgs; [
        all-the-icons
        counsel
        doom-modeline
        doom-themes
        evil
        evil-collection
        evil-org
        general
        ivy
        kanban
        ligature
        magit
        neotree
        org
        org-jira
        projectile
        swiper
        transient
        which-key
      ];

    extraConfig = ''
      ;; Evil setup
      (setq evil-want-keybinding nil)
      (setq evil-want-integration t)
      (require 'evil)
      (evil-mode 1)
      (require 'evil-collection)
      (evil-collection-init)

      ;; Evil org
      (require 'evil-org)
      (add-hook 'org-mode-hook 'evil-org-mode)
      (require 'evil-org-agenda)
      (evil-org-agenda-set-keys)

      ;; Doom aesthetic
      (require 'doom-themes)
      (load-theme 'doom-one t)
      (doom-themes-org-config)
      (doom-themes-neotree-config)
      (require 'doom-modeline)
      (doom-modeline-mode 1)

      ;; Clean UI
      (menu-bar-mode -1)
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
      (global-display-line-numbers-mode 1)

      ;; Which-key for discoverability
      (require 'which-key)
      (which-key-mode 1)
      (setq which-key-idle-delay 0.3)

      ;; Ivy/Counsel for completion
      (require 'ivy)
      (require 'counsel)
      (ivy-mode 1)
      (counsel-mode 1)
      (setq ivy-use-virtual-buffers t)

      ;; Projectile for project management
      (require 'projectile)
      (projectile-mode 1)
      (setq projectile-completion-system 'ivy)

      ;; Neotree file explorer
      (require 'neotree)
      (setq neo-theme 'icons)

      ;; General for keybindings with SPC leader
      (require 'general)
      (general-create-definer leader-def
        :states '(normal visual motion)
        :keymaps 'override
        :prefix "SPC")

      ;; File keybindings
      (leader-def
        "f" '(:ignore t :which-key "files")
        "f f" '(counsel-find-file :which-key "find file")
        "f s" '(save-buffer :which-key "save file")
        "f r" '(counsel-recentf :which-key "recent files")
        "f g" '(counsel-rg :which-key "grep/search project"))

      ;; Explorer keybindings
      (leader-def
        "e" '(:ignore t :which-key "explorer")
        "e t" '(neotree-toggle :which-key "file tree"))

      ;; Search keybindings
      (leader-def
        "s" '(:ignore t :which-key "search")
        "s s" '(swiper :which-key "search buffer"))

      ;; Org keybindings
      (leader-def
        "o" '(:ignore t :which-key "org")
        "o a" '(org-agenda :which-key "agenda")
        "o d" '(dired :which-key "dired"))

      ;; Org-mode specific (SPC m)
      (leader-def
        "m" '(:ignore t :which-key "org-mode")
        "m t" '(org-todo :which-key "cycle TODO"))

      ;; Kanban keybindings
      (leader-def
        "k" '(:ignore t :which-key "kanban")
        "k o" '(kanban-board :which-key "open kanban")
        "k l" '(org-shiftright :which-key "shift right")
        "k h" '(org-shiftleft :which-key "shift left")
        "k d" '(org-cut-subtree :which-key "delete task"))

      ;; JIRA keybindings
      (leader-def
        "j" '(:ignore t :which-key "jira")
        "j i" '(org-jira-get-issues :which-key "get issues")
        "j c" '(org-jira-create-issue :which-key "create issue")
        "j b" '(org-jira-browse-issue :which-key "browse issue")
        "j u" '(org-jira-update-issue :which-key "update issue")
        "j m" '(org-jira-add-comment :which-key "add comment"))

      ;; Buffer keybindings
      (leader-def
        "b" '(:ignore t :which-key "buffers")
        "b b" '(counsel-switch-buffer :which-key "switch buffer")
        "b k" '(kill-buffer :which-key "kill buffer"))

      ;; Org settings
      (setq org-todo-keywords
            '((sequence "TODO" "IN PROGRESS" "|" "DONE")))
      (setq org-log-done 'time)
      (setq org-directory
            (string-trim (shell-command-to-string "zoxide query org")))
      (setq org-agenda-files (list org-directory))

      ;; Auto-save and auto-commit on save
      (defun auto-commit-org ()
        "Auto commit org files on save."
        (when (and (buffer-file-name)
                   (string-match-p "\\.org$" (buffer-file-name))
                   (vc-git-root (buffer-file-name)))
          (let ((default-directory (vc-git-root (buffer-file-name))))
            (shell-command (format "git add %s && git commit -m 'auto: update %s' && git push"
                                   (shell-quote-argument (buffer-file-name))
                                   (file-name-nondirectory (buffer-file-name)))))))
      (add-hook 'after-save-hook 'auto-commit-org)

      ;; Ligature support
      (when (fboundp 'global-ligature-mode)
        (global-ligature-mode 1))

      ;; Org-jira settings
      (setq jiralib-url (getenv "JIRA_URL"))
    '';
  };
}
