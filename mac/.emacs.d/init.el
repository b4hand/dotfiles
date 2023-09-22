(setenv "PATH" (concat "/usr/local/bin:" (getenv "PATH")))
(push "/usr/local/bin" exec-path)

(when (>= emacs-major-version 24)
  (require 'package)
  ;; As of 2021-10-20 marmalade appears to be down
  ;; (add-to-list
  ;;  'package-archives
  ;;  '("marmalade" . "http://marmalade-repo.org/packages/"))
  (add-to-list
   'package-archives
   '("org" . "https://orgmode.org/elpa/")
   t)
  (add-to-list
   'package-archives
   '("melpa" . "https://melpa.org/packages/")
   t)
  (add-to-list
   'package-archives
   '("melpa-stable" . "https://stable.melpa.org/packages/")
   t)
  (package-initialize)
  (when (not package-archive-contents)
    (package-refresh-contents)
    (package-install 'use-package))
  (require 'use-package))

;; don't think this is actually letting the server work on Mac.
(setq server-socket-dir "~/.emacs.d/server")
;; (server-start)

;; Always use cperl-mode instead of the standard perl-mode
(defalias 'perl-mode 'cperl-mode)

;; ensime is no longer available
;; (use-package ensime
;;   :ensure t
;;   :pin melpa-stable)

(use-package projectile :ensure t)
(use-package yasnippet :ensure t)
(use-package lsp-mode :ensure t)
(use-package hydra :ensure t)
(use-package company
  :ensure t
  :bind (:map company-active-map
         ("<tab>" . company-indent-or-complete-common)
         ("M-n" . company-select-next)
         ("M-p" . company-select-previous))
  :config
  (setq company-idle-delay 0.03)
  (global-company-mode t))
(use-package lsp-ui :ensure t)
(use-package lsp-java :ensure t :after lsp
  :config (add-hook 'java-mode-hook 'lsp))
(use-package flycheck
  :ensure t
  :init (global-flycheck-mode))

(use-package ido
  :config
  (ido-mode t))

;; -----------------------------------------------------------------------------
;; Git support
;; -----------------------------------------------------------------------------
(use-package magit
  :ensure t)
(use-package git-blamed
  :ensure t)
(add-to-list 'vc-handled-backends 'GIT)

(use-package go-mode
  :ensure t)

(use-package protobuf-mode
  :ensure t
  :mode "\\.proto\\'")

(use-package graphql :ensure t)

(use-package graphviz-dot-mode
  :ensure t)

(use-package terraform-mode :ensure t)

;; Enable auto spell checking everywhere
;; (add-hook 'text-mode-hook 'flyspell-mode)
;; (add-hook 'prog-mode-hook 'flyspell-prog-mode)

(global-set-key (kbd "C-x C-n") 'next-error)
(global-set-key (kbd "C-x C-p") 'previous-error)

;; disable Cmd-K binding for kill-buffer which is too easy to press
;; accidentally.
(global-unset-key (kbd "s-k"))

(global-set-key (kbd "s-+") 'text-scale-increase)
(global-set-key (kbd "s--") 'text-scale-decrease)
(global-set-key (kbd "s-0") 'text-scale-adjust)

;; Make initial frame the desired size and position
(when window-system
  (set-frame-position (selected-frame) 0 0)
  (set-frame-size (selected-frame) 91 80))

;; Use C++ mode even for .c and .h files since I rarely develop pure C
;; code anymore.
(push '("\\.[ch]\\'" . c++-mode) auto-mode-alist)

(require 'cc-mode)

;; ;; Enable ggtags-mode for supported languages
;; (add-hook
;;  'prog-mode-hook
;;  (lambda ()
;;    (when (derived-mode-p 'c-mode 'c++-mode 'java-mode 'python-mode 'ruby-mode)
;;      (ggtags-mode 1))))

(defun un-camelcase-word-at-point ()
  "un-camelcase the word at point, replacing uppercase chars with
the lowercase version preceded by an underscore.
The first char, if capitalized (eg, PascalCase) is just
downcased, no preceding underscore.
"
  (interactive)
  (save-excursion
    (let ((bounds (bounds-of-thing-at-point 'word)))
      (replace-regexp "\\([A-Z]\\)" "_\\1" nil
                      (1+ (car bounds)) (cdr bounds))
      (downcase-region (car bounds) (cdr bounds)))))

(defun my-increment-number-decimal (&optional arg)
  "Increment the number forward from point by 'arg'."
  (interactive "p*")
  (save-excursion
    (save-match-data
      (let (inc-by field-width answer)
        (setq inc-by (if arg arg 1))
        (skip-chars-backward "0123456789")
        (when (re-search-forward "[0-9]+" nil t)
          (setq field-width (- (match-end 0) (match-beginning 0)))
          (setq answer (+ (string-to-number (match-string 0) 10) inc-by))
          (when (< answer 0)
            (setq answer (+ (expt 10 field-width) answer)))
          (replace-match (format (concat "%0" (int-to-string field-width) "d")
                                 answer)))))))

(global-set-key (kbd "C-c +") 'my-increment-number-decimal)

;; Lines up cascaded method calls
(defun my-java-lineup-cascaded-calls (langelem)
  (save-excursion
    (back-to-indentation)
    (let ((operator (and (looking-at "\\.")
                         (regexp-quote (match-string 0))))
          (stmt-start (c-langelem-pos langelem)) col)

      (when (and operator
                 (looking-at operator)
                 (zerop (c-backward-token-2 1 t stmt-start)))
        (if (and (eq (char-after) ?\()
                 (zerop (c-backward-token-2 2 t stmt-start))
                 (looking-at operator))
            (progn
              (setq col (current-column))

              (while (and (zerop (c-backward-token-2 1 t stmt-start))
                          (eq (char-after) ?\()
                          (zerop (c-backward-token-2 2 t stmt-start))
                          (looking-at operator))
                (setq col (current-column)))
              (vector col))
          (vector (+ (current-column)
                     c-basic-offset)))))))

(defun set-forehand-style ()
  "Set style to 'forehand'"
  (c-add-style "forehand" '(
    (c-recognize-knr-p . nil)
    (c-basic-offset . 4)
    (c-comment-only-line-offset . 0)
    (c-offsets-alist
      (arglist-intro . +)
      (arglist-cont-nonempty . +)
      (arglist-cont . my-java-lineup-cascaded-calls)
      (arglist-close . 0)
      (statement-block-intro . +)
      (inline-open . 0)
      (substatement-open . 0)
      (substatement-label . 0)
      (label . 0)
      (statement-cont . +))))
  (c-set-style "forehand"))
(add-hook 'c++-mode-hook 'set-forehand-style)

(add-hook 'java-mode-hook
  (lambda ()
    ;; "Treat Java 1.5 @-style annotations as comments."
    ;; (setq c-comment-start-regexp "(@|/(/|[*][*]?))")
    ;; (modify-syntax-entry ?@ "< b" java-mode-syntax-table)
    (progn
      (set-forehand-style)
      (setq c-basic-offset 2))))

(defun un-camelcase-word-at-point ()
  "un-camelcase the word at point, replacing uppercase chars with
the lowercase version preceded by an underscore.

The first char, if capitalized (eg, PascalCase) is just
downcased, no preceding underscore.
"
  (interactive)
  (save-excursion
    (let ((bounds (bounds-of-thing-at-point 'word)))
      (replace-regexp "\\([A-Z]\\)" "_\\1" nil
                      (1+ (car bounds)) (cdr bounds))
      (downcase-region (car bounds) (cdr bounds)))))

(defun my-increment-number-decimal (&optional arg)
  "Increment the number forward from point by 'arg'."
  (interactive "p*")
  (save-excursion
    (save-match-data
      (let (inc-by field-width answer)
        (setq inc-by (if arg arg 1))
        (skip-chars-backward "0123456789")
        (when (re-search-forward "[0-9]+" nil t)
          (setq field-width (- (match-end 0) (match-beginning 0)))
          (setq answer (+ (string-to-number (match-string 0) 10) inc-by))
          (when (< answer 0)
            (setq answer (+ (expt 10 field-width) answer)))
          (replace-match (format (concat "%0" (int-to-string field-width) "d")
                                 answer)))))))

(global-set-key (kbd "C-c +") 'my-increment-number-decimal)

;; ;; Setup auto-complete
;; (require 'auto-complete)
;; (require 'auto-complete-config)
;; (ac-config-default)
;; (ac-set-trigger-key "TAB")

(use-package yaml-mode
  :ensure t
  :mode "\\.sls\\'")
(use-package markdown-mode
  :ensure t)
(add-to-list 'auto-mode-alist '("\\.ya?ml$" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.sls$" . yaml-mode))
(add-to-list 'auto-mode-alist '("\\.md$" . markdown-mode))

;; From http://emacsredux.com/blog/2013/05/22/smarter-navigation-to-the-beginning-of-a-line/
(defun smarter-move-beginning-of-line (arg)
  "Move point back to indentation of beginning of line.

Move point to the first non-whitespace character on this line.
If point is already there, move to the beginning of the line.
Effectively toggle between the first non-whitespace character and
the beginning of the line.

If ARG is not nil or 1, move forward ARG - 1 lines first.  If
point reaches the beginning or end of the buffer, stop there."
  (interactive "^p")
  (setq arg (or arg 1))

  ;; Move lines first
  (when (/= arg 1)
    (let ((line-move-visual nil))
      (forward-line (1- arg))))

  (let ((orig-point (point)))
    (back-to-indentation)
    (when (= orig-point (point))
      (move-beginning-of-line 1))))

;; remap C-a to `smarter-move-beginning-of-line'
(global-set-key [remap move-beginning-of-line]
                'smarter-move-beginning-of-line)

;; ;; Configure and enable "clean-mode-line"
;; (defvar mode-line-cleaner-alist
;;   `((auto-complete-mode . " α")
;;     (yas/minor-mode . " υ")
;;     (abbrev-mode . "")
;;     ;; Major modes
;;     (lisp-interaction-mode . "λ")
;;     (python-mode . "Py")
;;     (emacs-lisp-mode . "EL")
;;     (nxhtml-mode . "nx"))
;;   "Alist for `clean-mode-line'.

;; When you add a new element to the alist, keep in mind that you
;; must pass the correct minor/major mode symbol and a string you
;; want to use in the modeline *in lieu of* the original.")

;; (defun clean-mode-line ()
;;   (interactive)
;;   (loop for cleaner in mode-line-cleaner-alist
;;         do (let* ((mode (car cleaner))
;;                  (mode-str (cdr cleaner))
;;                  (old-mode-str (cdr (assq mode minor-mode-alist))))
;;              (when old-mode-str
;;                  (setcar old-mode-str mode-str))
;;                ;; major mode
;;              (when (eq mode major-mode)
;;                (setq mode-name mode-str)))))

;; (add-hook 'after-change-major-mode-hook 'clean-mode-line)

;; highlight trailing whitespace in diff-mode, but not for blank context lines
(defvar diff-trailing-whitespace-keywords
  '(("^[+-<>]\\(.*\\S \\)?\\(\\s +\\)$" (2 'trailing-whitespace t))))
(defun diff-mode-font-lock-add-trailing-whitespace ()
  (setq diff-font-lock-keywords-and-whitespace
    (append diff-font-lock-keywords
        diff-trailing-whitespace-keywords))
  (setcar diff-font-lock-defaults 'diff-font-lock-keywords-and-whitespace))
(defun turn-off-trailing-whitespace ()
  (setq show-trailing-whitespace nil))
(add-hook 'diff-mode-hook 'turn-off-trailing-whitespace)
(eval-after-load "diff-mode" '(diff-mode-font-lock-add-trailing-whitespace))

(use-package elpy
  :ensure t
  :init
  (elpy-enable))

(eval-after-load "linum"
  '(set-face-attribute 'linum nil :height 100))

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(ansi-color-names-vector
   ["#26292c" "#ff4a52" "#40b83e" "#f6f080" "#afc4db" "#dc8cc3" "#93e0e3" "#f8f8f8"])
 '(c-basic-offset 2)
 '(c-default-style
   (quote
    ((c++-mode . "forehand")
     (java-mode . "java")
     (awk-mode . "awk")
     (other . "gnu"))))
 '(column-number-mode t)
 '(custom-enabled-themes '(deeper-blue))
 '(desktop-save-mode t)
 '(electric-indent-mode nil)
 '(elpy-rpc-python-command "python3")
 '(fci-rule-color "#202325")
 '(global-linum-mode t)
 '(gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
 '(indent-tabs-mode nil)
 '(inhibit-startup-screen t)
 '(js-indent-level 2)
 '(mouse-drag-copy-region nil)
 '(package-selected-packages
   '(terraform-mode flycheck graphviz-dot-mode lsp-ui company-lsp hydra projectile lsp-java markdown-mode with-editor magit protobuf-mode go-mode desktop-save-mode elpy yaml-mode git-blamed git ensime use-package))
 '(python-shell-interpreter "python3")
 '(read-quoted-char-radix 16)
 '(ruby-deep-indent-paren nil)
 '(safe-local-variable-values '((encoding . utf-8)))
 '(savehist-mode t)
 '(scroll-bar-mode nil)
 '(select-enable-clipboard t)
 '(select-enable-primary nil)
 '(show-paren-mode t)
 '(show-trailing-whitespace t)
 '(tags-table-list (quote ("~/src/TAGS")))
 '(tool-bar-mode nil)
 '(vc-annotate-background "#1f2124")
 '(vc-annotate-color-map
   (quote
    ((20 . "#ff0000")
     (40 . "#ff4a52")
     (60 . "#f6aa11")
     (80 . "#f1e94b")
     (100 . "#f5f080")
     (120 . "#f6f080")
     (140 . "#41a83e")
     (160 . "#40b83e")
     (180 . "#b6d877")
     (200 . "#b7d877")
     (220 . "#b8d977")
     (240 . "#b9d977")
     (260 . "#93e0e3")
     (280 . "#72aaca")
     (300 . "#8996a8")
     (320 . "#afc4db")
     (340 . "#cfe2f2")
     (360 . "#dc8cc3"))))
 '(vc-annotate-very-old-color "#dc8cc3")
 '(x-select-enable-clipboard t)
 '(x-select-enable-primary nil))
