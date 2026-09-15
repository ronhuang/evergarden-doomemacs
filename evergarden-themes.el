;;; evergarden-themes.el --- Evergarden themes for GNU Emacs -*- lexical-binding: t; -*-

;; Author: Ron Hu
;; Maintainer: Ron Hu
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: faces, themes
;; URL: https://github.com/ronhu/evergarden-doomemacs
;; SPDX-License-Identifier: Apache-2.0

;;; Commentary:

;; Evergarden is a cozy theme family built around four flavors -- Winter,
;; Fall, Spring and Summer -- and twelve accents -- red, orange, yellow, lime,
;; green, aqua, skye, snow, blue, purple, pink and cherry -- for 48
;; combinations in all.
;;
;; This library mirrors the architecture of the official Neovim port:
;; Whiskers generates the raw palette data (evergarden-palette-*.el) and this
;; library turns that data into Emacs faces.  Every flavor/accent pair is
;; registered as a theme in its own right, so `evergarden-winter-yellow' can
;; be passed to `load-theme' or assigned to `doom-theme'.
;;
;; The face mapping follows the Neovim port's hl groups: syntax colors are
;; fixed per flavor, while the accent drives the cursor, the active tab and
;; the completion/picker selection.

;;; Code:

(require 'cl-lib)
(require 'color)

(defgroup evergarden-themes nil
  "Evergarden themes for GNU Emacs."
  :group 'faces
  :prefix "evergarden-"
  :link '(url-link "https://github.com/ronhu/evergarden-doomemacs"))


;;
;;; Flavors and accents

(defconst evergarden--flavors '(winter fall spring summer)
  "Evergarden flavors, in Whiskers palette order.")

(defconst evergarden--accents
  '(red orange yellow lime green aqua skye snow blue purple pink cherry)
  "Evergarden accents, in Whiskers palette order.")

(defconst evergarden--colors
  '(red orange yellow lime green aqua skye snow blue purple pink cherry
    text subtext1 subtext0 overlay2 overlay1 overlay0
    surface2 surface1 surface0 base mantle crust)
  "Every palette color name, in the order Whiskers emits them.")

(defconst evergarden--flavor-meta
  '((winter "Winter" t)
    (fall   "Fall"   t)
    (spring "Spring" t)
    (summer "Summer" nil))
  "Alist of (FLAVOR NAME DARK-P).")


;;
;;; Options

(defcustom evergarden-flavor 'winter
  "Evergarden flavor to use.
The `evergarden-*' rotation commands update this."
  :type `(choice ,@(mapcar (lambda (f) `(const ,f)) evergarden--flavors))
  :group 'evergarden-themes)

(defcustom evergarden-accent 'yellow
  "Evergarden accent to use.
The `evergarden-*' rotation commands update this."
  :type `(choice ,@(mapcar (lambda (a) `(const ,a)) evergarden--accents))
  :group 'evergarden-themes)

(defcustom evergarden-transparent-background nil
  "When non-nil, do not set a background on the `default' face."
  :type 'boolean
  :group 'evergarden-themes)

(defcustom evergarden-cursor-color 'accent
  "Background color of the `cursor' face.
`accent' follows the selected accent, `none' leaves the cursor to Emacs, and
any palette color name can be used instead."
  :type `(choice (const accent) (const none)
                 ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors))
  :group 'evergarden-themes)

(defcustom evergarden-sign-color 'none
  "Background color of the sign column, or `none' for transparency."
  :type `(choice (const none) ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors))
  :group 'evergarden-themes)

(defcustom evergarden-float-color 'mantle
  "Background color of floating frames, or `none'."
  :type `(choice (const none) ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors))
  :group 'evergarden-themes)

(defcustom evergarden-float-solid-border nil
  "When non-nil, draw solid borders around floating frames."
  :type 'boolean
  :group 'evergarden-themes)

(defcustom evergarden-completion-color 'mantle
  "Background color of completion popups, or `none'."
  :type `(choice (const none) ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors))
  :group 'evergarden-themes)

(defcustom evergarden-completion-selected-color 'surface0
  "Background color of the selected completion candidate."
  :type `(choice (const none) ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors))
  :group 'evergarden-themes)

(defcustom evergarden-completion-selected-style '(bold)
  "Style of the selected completion candidate."
  :type '(repeat (choice (const bold) (const italic) (const underline)
                         (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-statusline-active '(:fg subtext0 :bg mantle)
  "Colors of the active status line, as a plist of `:fg' and `:bg'."
  :type `(plist :key-type (choice (const :fg) (const :bg))
                :value-type (choice (const none)
                                    ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors)))
  :group 'evergarden-themes)

(defcustom evergarden-statusline-inactive '(:fg overlay1 :bg mantle)
  "Colors of inactive status lines, as a plist of `:fg' and `:bg'."
  :type `(plist :key-type (choice (const :fg) (const :bg))
                :value-type (choice (const none)
                                    ,@(mapcar (lambda (c) `(const ,c)) evergarden--colors)))
  :group 'evergarden-themes)

(defcustom evergarden-style-tabline '(reverse)
  "Style of the active tab."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-search '(italic reverse)
  "Style of the current search match."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-incsearch nil
  "Style of incremental search matches."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-diagnostics '(underline)
  "Style of diagnostic underlines."
  :type '(repeat (choice (const bold) (const italic) (const undercurl)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-types '(italic)
  "Style of type faces."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-keyword '(italic)
  "Style of keyword faces."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-comment '(italic)
  "Style of comment faces."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-spell '(underline)
  "Style of spelling mistakes."
  :type '(repeat (choice (const bold) (const italic) (const undercurl)
                         (const underline) (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-style-disable nil
  "Styles to remove from every face."
  :type '(repeat (choice (const bold) (const italic) (const reverse)
                         (const underline) (const undercurl)
                         (const strikethrough)))
  :group 'evergarden-themes)

(defcustom evergarden-overrides nil
  "Alist of face overrides, mirroring the Neovim port's `overrides'.

Each element is (FACE . SPEC).  SPEC is either a plist with `:fg', `:bg' and
`:style' keys, or a shorthand list of (FG BG) / (FG BG STYLE) where the
colors are hex strings.  Examples:

  ((default :bg \"#000000\")
   (font-lock-keyword-face \"#fddce3\" \"#1d2021\")
   (font-lock-string-face :fg \"#9ece6a\" :style (bold)))"
  :type '(alist :key-type symbol :value-type sexp)
  :group 'evergarden-themes)

(defvar evergarden-after-load-theme-hook nil
  "Hook run after an Evergarden theme is loaded.")


;;
;;; Palette data

(defun evergarden--palette (flavor)
  "Return the color alist for FLAVOR."
  (let ((feature (intern (format "evergarden-palette-%s" flavor))))
    (unless (featurep feature)
      (require feature))
    (symbol-value feature)))


;;
;;; Theme construction

(defun evergarden--color (colors name &optional fallback)
  "Return the hex color for NAME in COLORS.
NAME may be a color symbol, `none' for no color, or nil for FALLBACK."
  (cond ((null name) fallback)
        ((eq name 'none) nil)
        (t (or (cdr (assq name colors)) fallback))))

(defun evergarden--theme (flavor accent)
  "Return a plist describing the FLAVOR/ACCENT theme.
Mirrors `evergarden.theme.setup' in the official Neovim port."
  (let* ((colors (evergarden--palette flavor))
         (accent-color (or (cdr (assq accent colors)) (cdr (assq 'green colors))))
         (cursor (pcase evergarden-cursor-color
                   ('accent accent-color)
                   ('none nil)
                   (_ (cdr (assq evergarden-cursor-color colors)))))
         (sign (and (not (eq evergarden-sign-color 'none))
                    (cdr (assq evergarden-sign-color colors)))))
    (list
     :flavor flavor
     :colors colors
     :accent accent-color
     :cursor cursor
     :sign sign
     :comment (cdr (assq 'overlay2 colors))
     :editor (list
              :search (cdr (assq 'snow colors))
              :incsearch (cdr (assq 'orange colors))
              :float (evergarden--color colors evergarden-float-color)
              :completion (evergarden--color colors evergarden-completion-color)
              :completion-selected (evergarden--color colors evergarden-completion-selected-color)
              :completion-selected-style evergarden-completion-selected-style
              :statusline-active
              (list :fg (evergarden--color colors (plist-get evergarden-statusline-active :fg))
                    :bg (evergarden--color colors (plist-get evergarden-statusline-active :bg)))
              :statusline-inactive
              (list :fg (evergarden--color colors (plist-get evergarden-statusline-inactive :fg))
                    :bg (evergarden--color colors (plist-get evergarden-statusline-inactive :bg))))
     :syntax (list
              :keyword (cdr (assq 'red colors))
              :identifier (cdr (assq 'text colors))
              :property (cdr (assq 'skye colors))
              :type (cdr (assq 'yellow colors))
              :context (cdr (assq 'overlay1 colors))
              :operator (cdr (assq 'subtext0 colors))
              :constant (cdr (assq 'pink colors))
              :func (cdr (assq 'green colors))
              :string (cdr (assq 'lime colors))
              :macro (cdr (assq 'cherry colors))
              :annotation (cdr (assq 'cherry colors)))
     :diagnostic (list
                  :ok (cdr (assq 'green colors))
                  :error (cdr (assq 'red colors))
                  :warn (cdr (assq 'yellow colors))
                  :info (cdr (assq 'aqua colors))
                  :hint (cdr (assq 'skye colors)))
     :diff (list
            :add (cdr (assq 'green colors))
            :delete (cdr (assq 'red colors))
            :change (cdr (assq 'aqua colors))))))

(defun evergarden--blend (fg bg alpha)
  "Blend FG into BG by ALPHA (a number between 0 and 1)."
  (let ((a (color-name-to-rgb fg))
        (b (color-name-to-rgb bg)))
    (apply #'color-rgb-to-hex
           (append (cl-mapcar (lambda (x y) (+ (* x alpha) (* y (- 1 alpha)))) a b)
                   (list 2)))))

(defun evergarden--style-attrs (style &optional foreground)
  "Return a face attribute plist for STYLE, a list of style symbols.
FOREGROUND colors undercurl underlines."
  (let ((style (if evergarden-style-disable
                   (cl-set-difference style evergarden-style-disable)
                 style))
        attrs)
    (dolist (s style)
      (pcase s
        ('bold (setq attrs (plist-put attrs :weight 'bold)))
        ('italic (setq attrs (plist-put attrs :slant 'italic)))
        ('underline (setq attrs (plist-put attrs :underline t)))
        ('undercurl (setq attrs (plist-put attrs :underline
                                           (list :style 'wave :color foreground))))
        ('strikethrough (setq attrs (plist-put attrs :strike-through t)))))
    attrs))

(defun evergarden--attrs (fg bg &optional style extra)
  "Build a face attribute plist from FG, BG, STYLE and EXTRA.
A `reverse' in STYLE swaps FG and BG, matching the Neovim port."
  (let* ((style (or style '()))
         (reverse (memq 'reverse style))
         (style (delq 'reverse (copy-sequence style)))
         (f (if reverse bg fg))
         (b (if reverse fg bg)))
    (append (when f (list :foreground f))
            (when b (list :background b))
            (evergarden--style-attrs style f)
            extra)))


;;
;;; Faces

(defun evergarden--faces (theme)
  "Return an alist of (FACE . ATTRS) described by THEME."
  (let* ((flavor (plist-get theme :flavor))
         (colors (plist-get theme :colors))
         (accent (plist-get theme :accent))
         (syntax (plist-get theme :syntax))
         (diag (plist-get theme :diagnostic))
         (diff (plist-get theme :diff))
         (editor (plist-get theme :editor))
         (sign (plist-get theme :sign))
         (comment (plist-get theme :comment))
         (search (plist-get editor :search))
         (incsearch (plist-get editor :incsearch))
         (float (plist-get editor :float))
         (completion (plist-get editor :completion))
         (selected (plist-get editor :completion-selected))
         (selected-style (plist-get editor :completion-selected-style))
         (sl-active (plist-get editor :statusline-active))
         (sl-inactive (plist-get editor :statusline-inactive))
         (light (not (evergarden--dark-p flavor))))
    (cl-labels ((c (name) (cdr (assq name colors)))
                (a (fg bg &optional style extra)
                   (evergarden--attrs fg bg style extra)))
      (append
       ;; Canvas and chrome.
       (list
        (cons 'default (a (c 'text)
                          (unless evergarden-transparent-background (c 'base))))
        (cons 'cursor (a (c 'crust) (plist-get theme :cursor)))
        (cons 'region (a nil (c 'surface1)))
        (cons 'hl-line (a nil (c 'surface0)))
        (cons 'fringe (a (c 'overlay1)
                         (unless evergarden-transparent-background (c 'base))))
        (cons 'line-number (a (c 'surface2) nil))
        (cons 'line-number-current-line (a (c 'overlay2) nil))
        (cons 'window-divider
              (a (if evergarden-transparent-background (c 'surface0) (c 'surface1)) nil))
        (cons 'vertical-border (a (c 'surface1) nil))
        (cons 'mode-line
              (a (plist-get sl-active :fg)
                 (unless evergarden-transparent-background (plist-get sl-active :bg))))
        (cons 'mode-line-inactive
              (a (plist-get sl-inactive :fg)
                 (unless evergarden-transparent-background (plist-get sl-inactive :bg))))
        (cons 'header-line (a (c 'subtext0) nil))
        (cons 'tab-bar (a (c 'overlay1) (c 'surface0)))
        (cons 'tab-bar-tab
              (if (memq 'reverse evergarden-style-tabline)
                  (a (c 'crust) accent)
                (a (c 'subtext1) (c 'surface0))))
        (cons 'tab-bar-tab-inactive (a (c 'overlay1) (c 'surface0)))
        (cons 'tab-line (a (c 'overlay1) (c 'surface0)))
        (cons 'tab-line-tab
              (if (memq 'reverse evergarden-style-tabline)
                  (a (c 'crust) accent)
                (a (c 'subtext1) (c 'surface0))))
        (cons 'tab-line-tab-inactive (a (c 'overlay1) (c 'surface0)))
        (cons 'minibuffer-prompt (a (c 'subtext0) nil))
        (cons 'shadow (a (c 'overlay1) nil))
        (cons 'link (a (c 'blue) nil nil '(:underline t)))
        (cons 'highlight (a nil (c 'surface0)))
        (cons 'tooltip (a (c 'text) (or float (c 'mantle))))
        (cons 'show-paren-match (a nil (c 'surface1) '(bold))))

       ;; Search.  The Neovim port resolves these through `vary_reverse': a
       ;; `reverse' style selects the alternate spec rather than swapping.
       (list
        (cons 'isearch
              (if (memq 'reverse evergarden-style-search)
                  (a (if light (c 'text) (c 'crust)) search)
                (a search nil (delq 'reverse evergarden-style-search))))
        (cons 'isearch-fail (a (c 'crust) (c 'red)))
        (cons 'lazy-highlight
              (if (memq 'reverse evergarden-style-search)
                  (a (c 'subtext1) (c 'surface1))
                (a (c 'surface1) nil (delq 'reverse evergarden-style-search))))
        (cons 'query-replace
              (if (memq 'reverse evergarden-style-incsearch)
                  (a (if light (c 'text) (c 'crust)) incsearch)
                (a incsearch nil (delq 'reverse evergarden-style-incsearch)))))

       ;; Completion and pickers.
       (list
        (cons 'completions-annotations (a (plist-get syntax :annotation) nil))
        (cons 'completions-common-part (a incsearch nil))
        (cons 'completions-first-difference (a nil nil '(bold)))
        (cons 'company-tooltip (a (c 'text) completion))
        (cons 'company-tooltip-selection
              (a nil selected selected-style))
        (cons 'company-tooltip-common (a incsearch completion))
        (cons 'company-tooltip-annotation
              (a (plist-get syntax :annotation) completion))
        (cons 'corfu-default (a (c 'text) completion))
        (cons 'corfu-current (a nil selected selected-style))
        (cons 'corfu-annotations (a (plist-get syntax :annotation) completion))
        (cons 'corfu-border (a (if evergarden-float-solid-border completion (c 'surface0))
                               completion))
        (cons 'vertico-current (a accent (c 'surface0) '(bold)))
        (cons 'ivy-current-match (a accent (c 'surface0) '(bold)))
        (cons 'helm-selection (a accent (c 'surface0) '(bold)))
        (cons 'helm-match (a incsearch nil)))

       ;; Diffs.
       (list
        (cons 'diff-added (a nil (evergarden--blend (plist-get diff :add) (c 'base) 0.16)))
        (cons 'diff-removed (a nil (evergarden--blend (plist-get diff :delete) (c 'base) 0.16)))
        (cons 'diff-changed (a nil (evergarden--blend (plist-get diff :change) (c 'base) 0.08)))
        (cons 'diff-refine-added
              (a nil (evergarden--blend (plist-get diff :add) (c 'base) 0.16)))
        (cons 'diff-refine-removed
              (a nil (evergarden--blend (plist-get diff :delete) (c 'base) 0.16)))
        (cons 'diff-refine-changed
              (a nil (evergarden--blend (plist-get diff :change) (c 'base) 0.16)))
        (cons 'diff-header (a (c 'text) nil))
        (cons 'diff-file-header (a (c 'text) nil '(bold))))

       ;; Messages, diagnostics and spelling.
       (list
        (cons 'error (a (plist-get diag :error) nil))
        (cons 'warning (a (plist-get diag :warn) nil))
        (cons 'success (a (plist-get diag :ok) nil))
        (cons 'flycheck-error
              (a (plist-get diag :error) nil evergarden-style-diagnostics))
        (cons 'flycheck-warning
              (a (plist-get diag :warn) nil evergarden-style-diagnostics))
        (cons 'flycheck-info
              (a (plist-get diag :info) nil evergarden-style-diagnostics))
        (cons 'flycheck-fringe-error (a (plist-get diag :error) sign))
        (cons 'flycheck-fringe-warning (a (plist-get diag :warn) sign))
        (cons 'flycheck-fringe-info (a (plist-get diag :info) sign))
        (cons 'flymake-error
              (a (plist-get diag :error) nil evergarden-style-diagnostics))
        (cons 'flymake-warning
              (a (plist-get diag :warn) nil evergarden-style-diagnostics))
        (cons 'flymake-note
              (a (plist-get diag :info) nil evergarden-style-diagnostics))
        (cons 'eglot-inlay-hint-face (a (c 'overlay1) nil))
        (cons 'lsp-inlay-hint-face (a (c 'overlay1) nil))
        (cons 'eldoc-highlight-function-argument (a nil nil '(bold)))
        (cons 'flyspell-incorrect (a (c 'red) nil evergarden-style-spell))
        (cons 'flyspell-duplicate (a (c 'aqua) nil evergarden-style-spell)))

       ;; Syntax.
       (list
        (cons 'font-lock-keyword-face
              (a (plist-get syntax :keyword) nil evergarden-style-keyword))
        (cons 'font-lock-type-face
              (a (plist-get syntax :type) nil evergarden-style-types))
        (cons 'font-lock-function-name-face (a (plist-get syntax :func) nil))
        (cons 'font-lock-variable-name-face (a (plist-get syntax :identifier) nil))
        (cons 'font-lock-constant-face (a (plist-get syntax :constant) nil))
        (cons 'font-lock-builtin-face (a (c 'orange) nil))
        (cons 'font-lock-string-face (a (plist-get syntax :string) nil))
        (cons 'font-lock-doc-face (a (c 'skye) nil))
        (cons 'font-lock-comment-face
              (a comment nil evergarden-style-comment))
        (cons 'font-lock-comment-delimiter-face
              (a comment nil evergarden-style-comment))
        (cons 'font-lock-preprocessor-face (a (plist-get syntax :annotation) nil))
        (cons 'font-lock-negation-char-face (a (c 'orange) nil))
        (cons 'font-lock-warning-face (a (c 'yellow) nil '(bold)))
        (cons 'font-lock-operator-face (a (plist-get syntax :operator) nil))
        (cons 'font-lock-property-face (a (plist-get syntax :property) nil))
        (cons 'font-lock-bracket-face (a (plist-get syntax :context) nil))
        (cons 'font-lock-delimiter-face (a (plist-get syntax :context) nil))
        (cons 'font-lock-escape-face (a (c 'yellow) nil))
        (cons 'font-lock-number-face (a (plist-get syntax :constant) nil))
        (cons 'font-lock-function-call-face (a (plist-get syntax :func) nil)))

       ;; ANSI terminal colors, mirroring the Neovim port.
       (list
        (cons 'ansi-color-black (a (c 'surface1) nil))
        (cons 'ansi-color-red (a (c 'red) nil))
        (cons 'ansi-color-green (a (c 'green) nil))
        (cons 'ansi-color-yellow (a (c 'yellow) nil))
        (cons 'ansi-color-blue (a (c 'blue) nil))
        (cons 'ansi-color-magenta (a (c 'pink) nil))
        (cons 'ansi-color-cyan (a (c 'aqua) nil))
        (cons 'ansi-color-white (a (c 'subtext0) nil))
        (cons 'ansi-color-bright-black (a (c 'overlay1) nil))
        (cons 'ansi-color-bright-red (a (c 'red) nil))
        (cons 'ansi-color-bright-green (a (c 'green) nil))
        (cons 'ansi-color-bright-yellow (a (c 'yellow) nil))
        (cons 'ansi-color-bright-blue (a (c 'blue) nil))
        (cons 'ansi-color-bright-magenta (a (c 'pink) nil))
        (cons 'ansi-color-bright-cyan (a (c 'aqua) nil))
        (cons 'ansi-color-bright-white (a (c 'subtext1) nil)))))))

(defun evergarden--apply-override (face attrs)
  "Apply the user's `evergarden-overrides' entry for FACE to ATTRS."
  (let ((override (cdr (assq face evergarden-overrides))))
    (cond
     ((null override) attrs)
     ;; Plist form: (:fg "#..." :bg "#..." :style (bold))
     ((keywordp (car override))
      (let* ((fg (plist-get override :fg))
             (bg (plist-get override :bg))
             (style (plist-get override :style))
             (attrs (copy-sequence attrs)))
        (when fg (setq attrs (plist-put attrs :foreground fg)))
        (when bg (setq attrs (plist-put attrs :background bg)))
        (when style
          (setq attrs (append (evergarden--style-attrs style (plist-get attrs :foreground))
                              attrs)))
        attrs))
     ;; Shorthand: ("#fg" "#bg") / ("#fg" "#bg" (bold))
     (t
      (let ((attrs (copy-sequence attrs)))
        (when (nth 0 override) (setq attrs (plist-put attrs :foreground (nth 0 override))))
        (when (nth 1 override) (setq attrs (plist-put attrs :background (nth 1 override))))
        (when (nth 2 override)
          (setq attrs (append (evergarden--style-attrs (nth 2 override)
                                                       (plist-get attrs :foreground))
                              attrs)))
        attrs)))))

(defun evergarden--face-specs (flavor accent)
  "Return `custom-theme-set-faces' specs for FLAVOR and ACCENT."
  (mapcar (lambda (cell)
            (list (car cell)
                  (list (cons t (evergarden--apply-override (car cell) (cdr cell))))))
          (evergarden--faces (evergarden--theme flavor accent))))

(defmacro evergarden--deftheme (flavor accent)
  "Define the Evergarden theme for FLAVOR and ACCENT.
Generated theme files call this."
  (declare (indent 0))
  (let* ((name (evergarden--theme-symbol flavor accent))
         (feature (intern (format "%s-theme" name)))
         (doc (format "Evergarden %s flavor with the %s accent."
                      (evergarden--flavor-name flavor) accent)))
    `(progn
       (deftheme ,name ,doc)
       (apply #'custom-theme-set-faces ',name
              (evergarden--face-specs ',flavor ',accent))
       (provide ',feature))))


;;
;;; Helpers

(defun evergarden--theme-symbol (flavor accent)
  "Return the theme symbol for FLAVOR and ACCENT."
  (intern (format "evergarden-%s-%s" flavor accent)))

(defun evergarden--flavor-name (flavor)
  "Return the display name of FLAVOR."
  (or (nth 1 (assq flavor evergarden--flavor-meta))
      (capitalize (symbol-name flavor))))

(defun evergarden--dark-p (flavor)
  "Return non-nil if FLAVOR is a dark flavor."
  (if (assq flavor evergarden--flavor-meta)
      (nth 2 (assq flavor evergarden--flavor-meta))
    t))

(defun evergarden--label (flavor accent)
  "Return a human-readable label for FLAVOR and ACCENT."
  (format "%s · %s (%s)"
          (evergarden--flavor-name flavor) accent
          (evergarden--theme-symbol flavor accent)))

(defun evergarden--cycle (list value delta)
  "Return the element of LIST DELTA positions after VALUE, wrapping."
  (let* ((n (length list))
         (i (or (cl-position value list) 0)))
    (nth (mod (+ i delta) n) list)))

(defun evergarden--combos ()
  "Return the ordered list of all (FLAVOR . ACCENT) combinations."
  (cl-loop for flavor in evergarden--flavors
           nconc (cl-loop for accent in evergarden--accents
                          collect (cons flavor accent))))

(defun evergarden--read-flavor ()
  "Read an Evergarden flavor with completion."
  (intern (completing-read "Evergarden flavor: "
                           (mapcar #'symbol-name evergarden--flavors)
                           nil t nil nil (symbol-name evergarden-flavor))))

(defun evergarden--read-accent ()
  "Read an Evergarden accent with completion."
  (intern (completing-read "Evergarden accent: "
                           (mapcar #'symbol-name evergarden--accents)
                           nil t nil nil (symbol-name evergarden-accent))))


;;
;;; Loading and rotating

;;;###autoload
(defun evergarden-load-theme (flavor accent)
  "Load the Evergarden theme for FLAVOR and ACCENT.
This sets `evergarden-flavor' and `evergarden-accent', disables any other
Evergarden theme, loads the requested one and, inside Doom Emacs, keeps
`doom-theme' in sync."
  (interactive (list (evergarden--read-flavor) (evergarden--read-accent)))
  (let ((theme (evergarden--theme-symbol flavor accent)))
    (setq evergarden-flavor flavor
          evergarden-accent accent)
    (dolist (enabled custom-enabled-themes)
      (when (and (not (eq enabled theme))
                 (string-prefix-p "evergarden-" (symbol-name enabled)))
        (disable-theme enabled)))
    (load-theme theme t)
    (when (boundp 'doom-theme)
      (setq doom-theme theme))
    (run-hooks 'evergarden-after-load-theme-hook)
    (message "Evergarden: %s" (evergarden--label flavor accent))
    theme))

(defun evergarden--step (kind delta)
  "Move DELTA steps through the Evergarden theme space.
KIND is `theme', `flavor' or `accent'."
  (pcase kind
    ('accent
     (evergarden-load-theme
      evergarden-flavor
      (evergarden--cycle evergarden--accents evergarden-accent delta)))
    ('flavor
     (evergarden-load-theme
      (evergarden--cycle evergarden--flavors evergarden-flavor delta)
      evergarden-accent))
    (_
     (let* ((combos (evergarden--combos))
            (current (cons evergarden-flavor evergarden-accent))
            (i (or (cl-position current combos :test #'equal) 0))
            (next (nth (mod (+ i delta) (length combos)) combos)))
       (evergarden-load-theme (car next) (cdr next))))))

;;;###autoload
(defun evergarden-rotate (&optional delta)
  "Cycle DELTA steps through all 48 Evergarden flavor/accent combinations."
  (interactive "p")
  (evergarden--step 'theme (or delta 1)))

;;;###autoload
(defun evergarden-rotate-reverse ()
  "Cycle one step backwards through all Evergarden combinations."
  (interactive)
  (evergarden--step 'theme -1))

;;;###autoload
(defun evergarden-rotate-flavor (&optional delta)
  "Cycle DELTA steps through the Evergarden flavors, keeping the accent."
  (interactive "p")
  (evergarden--step 'flavor (or delta 1)))

;;;###autoload
(defun evergarden-rotate-flavor-reverse ()
  "Cycle one flavor backwards, keeping the accent."
  (interactive)
  (evergarden--step 'flavor -1))

;;;###autoload
(defun evergarden-rotate-accent (&optional delta)
  "Cycle DELTA steps through the Evergarden accents, keeping the flavor."
  (interactive "p")
  (evergarden--step 'accent (or delta 1)))

;;;###autoload
(defun evergarden-rotate-accent-reverse ()
  "Cycle one accent backwards, keeping the flavor."
  (interactive)
  (evergarden--step 'accent -1))

;;;###autoload
(defun evergarden-load-random ()
  "Load a random Evergarden flavor/accent combination."
  (interactive)
  (evergarden-load-theme
   (nth (random (length evergarden--flavors)) evergarden--flavors)
   (nth (random (length evergarden--accents)) evergarden--accents)))

;;;###autoload
(defun evergarden-select ()
  "Prompt for an Evergarden flavor/accent combination and load it."
  (interactive)
  (let* ((candidates
          (cl-loop for flavor in evergarden--flavors
                   nconc (cl-loop for accent in evergarden--accents
                                  collect (cons (format "%s · %s"
                                                        (evergarden--flavor-name flavor)
                                                        accent)
                                                (cons flavor accent)))))
         (choice (completing-read "Evergarden theme: " candidates nil t))
         (pair (cdr (assoc choice candidates))))
    (evergarden-load-theme (car pair) (cdr pair))))

;;;###autoload
(defun evergarden-select-flavor ()
  "Prompt for an Evergarden flavor and load it with the current accent."
  (interactive)
  (evergarden-load-theme (evergarden--read-flavor) evergarden-accent))

;;;###autoload
(defun evergarden-select-accent ()
  "Prompt for an Evergarden accent and load it with the current flavor."
  (interactive)
  (evergarden-load-theme evergarden-flavor (evergarden--read-accent)))

;;;###autoload
(defun evergarden-describe ()
  "Echo the current Evergarden flavor and accent."
  (interactive)
  (message "Evergarden: %s"
           (evergarden--label evergarden-flavor evergarden-accent)))

;;;###autoload
(when load-file-name
  (let ((dir (file-name-directory load-file-name)))
    (unless (file-equal-p dir (expand-file-name "themes/" data-directory))
      (add-to-list 'custom-theme-load-path dir))))

(provide 'evergarden-themes)
;;; evergarden-themes.el ends here
