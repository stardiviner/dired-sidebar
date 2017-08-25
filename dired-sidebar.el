;;;; dired-sidebar.el -- Tree browser leveraging dired -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2099  Free Software Foundation, Inc.

;; Author: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/dired-sidebar
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: dired

;; This file is part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides a tree browser similar to `neotree' or `treemacs'
;; but leverages `dired' to do the job of display.

;;
;; (use-package dired-subtree
;;   :ensure t
;;   :commands (dired-subtree-toggle dired-subtree-cycle)
;;   :config
;;   (setq dired-subtree-use-backgrounds nil))
;;
;; (use-package dired-sidebar
;;   :ensure nil
;;   :commands (dired-sidebar/toggle-sidebar)
;;   :config
;;   (use-package all-the-icons-dired
;;     :ensure t
;;     :commands (all-the-icons-dired-mode)))
;;

;;; Code:
(require 'dired)
(require 'dired-subtree)
(require 'evil nil t)
(require 'face-remap)
(require 'projectile nil t)

(defvar dired-sidebar-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [tab] 'dired-subtree-toggle)
    (with-eval-after-load 'evil
      (evil-define-key 'normal map [tab] 'dired-subtree-toggle))
    map)
  "Keymap used for `dired-sidebar-mode'.")

(define-minor-mode dired-sidebar-mode
  "A minor mode that leverages `dired' to emulate a Tree browser."
  :init-value nil
  :lighter ""
  :keymap dired-sidebar-mode-map

  (setq window-size-fixed 'width)

  (auto-revert-mode -1)

  ;; We don't want extra details in the sidebar.
  (dired-hide-details-mode)

  (when (fboundp 'all-the-icons-dired-mode)
    (all-the-icons-dired-mode))
  (dired-sidebar/set-font)
  (dired-sidebar/set-mode-line))

;; Customizations

(defgroup dired-sidebar nil
  "A major mode leveraging `dired-mode' to display a filesystem in a tree
layout."
  :group 'files)

(defcustom dired-sidebar/use-custom-font t
  "Show `dired-sidebar' with font face using `dired-sidebar/font-face'."
  :type 'boolean
  :group 'dired-sidebar)

(defvar dired-sidebar/font-face '(:family "Helvetica" :height 130)
  "Face used by `dired-sidebar' for font if `dired-sidebar/use-custom-font'
is true.")

(defcustom dired-sidebar/use-custom-modeline t
  "Show `dired-sidebar' with custom modeline using
`dired-sidebar/mode-line-format'."
  :type 'boolean
  :group 'dired-sidebar)

(defvar dired-sidebar/mode-line-format
  '("%e" mode-line-front-space
    mode-line-buffer-identification
    "  " (vc-mode vc-mode) "  "  mode-line-end-spaces)
  "Mode line format for `dired-sidebar'.")

;; User Interface

;;;###autoload
(defun dired-sidebar/toggle-sidebar ()
  "Toggle the project explorer window."
  (interactive)
  (let* ((root (dired-sidebar/sidebar-root))
         (name (dired-sidebar/sidebar-buffer-name root))
         (buffer (or (get-buffer name)
                     (dired-noselect root))))
    ;; Rename the buffer generated by `dired-noselect'.
    (when (not (string-equal (buffer-name buffer) name))
      (with-current-buffer buffer
        (rename-buffer name)))
    (if (get-buffer-window buffer)
        (dired-sidebar/hide-sidebar buffer)
      (dired-sidebar/show-sidebar buffer root)
      (pop-to-buffer buffer))))

;;;###autoload
(defun dired-sidebar/show-sidebar (buffer dir)
  "Project dired buffer on the side of the frame.
Shows the projectile root folder using dired on the left side of
the frame and makes it a dedicated window for that buffer."
  (display-buffer-in-side-window buffer '((side . left)
                                          (window-width . 0.2)))
  (set-window-dedicated-p (get-buffer-window buffer) t)
  (with-current-buffer buffer
    (dired-sidebar-mode)
    (dired-unadvertise dir)))

;;;###autoload
(defun dired-sidebar/hide-sidebar (buffer)
  "Hide the sidebar window."
  (delete-window (get-buffer-window buffer)))

;; Helpers

(defun dired-sidebar/sidebar-root ()
  "Return directory."
  (condition-case nil
      (projectile-project-root)
    (error default-directory)))

(defun dired-sidebar/sidebar-buffer-name (root)
  "Return name of buffer given ROOT."
  (abbreviate-file-name root))

(defun dired-sidebar/set-font ()
  "Set font to a variable width (proportional) fonts in current buffer"
  (interactive)
  (when dired-sidebar/use-custom-font
    (setq buffer-face-mode-face dired-sidebar/font-face)
    (buffer-face-mode)))

(defun dired-sidebar/set-mode-line ()
  "Set up modeline."
  (when dired-sidebar/use-custom-modeline
    (setq mode-line-format dired-sidebar/mode-line-format)))

(provide 'dired-sidebar)
;;; dired-sidebar.el ends here
