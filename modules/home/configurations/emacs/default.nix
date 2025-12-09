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
        evil
        evil-collection
        evil-org
        org
        doom-themes
        doom-modeline
        jira
        kanban
        slack
      ];

    extraConfig = ''
      (require 'evil)
      (evil-mode 1)
      (evil-collection-init)

      (require 'evil-org)
      (add-hook 'org-mode-hook 'evil-org-mode)

      (require 'doom-themes)
      (load-theme 'doom-one t)
      (doom-themes-org-config)
      (require 'doom-modeline)
      (doom-modeline-mode 1)

      (menu-bar-mode -1)
      (tool-bar-mode -1)
      (scroll-bar-mode -1)
    '';
  };
}
