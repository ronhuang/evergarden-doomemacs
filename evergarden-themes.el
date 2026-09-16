;;; evergarden-themes.el --- Evergarden themes for GNU Emacs -*- lexical-binding: t; -*-

;; Author: Ron Huang
;; Maintainer: Ron Huang
;; Version: 0.1.0
;; Package-Requires: ((emacs "28.1"))
;; Keywords: faces, themes
;; URL: https://github.com/ronhuang/evergarden-doomemacs
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

(defgroup evergarden-themes nil
  "Evergarden themes for GNU Emacs."
  :group 'faces
  :prefix "evergarden-"
  :link '(url-link "https://github.com/ronhuang/evergarden-doomemacs"))


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

(defun evergarden--style-widget-type (&optional undercurl reverse)
  "Return a widget type for lists of face style symbols.
UNDERCURL admits the `undercurl' style and REVERSE the `reverse'
style; bold, italic, underline and strikethrough are always allowed."
  `(repeat (choice ,@(append '(const bold) '(const italic)
                             (when reverse '((const reverse)))
                             '(const underline)
                             (when undercurl '((const undercurl)))
                             '(const strikethrough)))))

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
  :type (evergarden--style-widget-type)
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
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-search '(italic reverse)
  "Style of the current search match."
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-incsearch nil
  "Style of incremental search matches."
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-diagnostics '(underline)
  "Style of diagnostic underlines."
  :type (evergarden--style-widget-type t)
  :group 'evergarden-themes)

(defcustom evergarden-style-types '(italic)
  "Style of type faces."
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-keyword '(italic)
  "Style of keyword faces."
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-comment '(italic)
  "Style of comment faces."
  :type (evergarden--style-widget-type nil t)
  :group 'evergarden-themes)

(defcustom evergarden-style-spell '(underline)
  "Style of spelling mistakes."
  :type (evergarden--style-widget-type t)
  :group 'evergarden-themes)

(defcustom evergarden-style-disable nil
  "Styles to remove from every face."
  :type (evergarden--style-widget-type t t)
  :group 'evergarden-themes)

(defcustom evergarden-headings nil
  "Extra face attributes for heading faces (à la modus-themes-headings).
An alist of (LEVEL . ATTRS).  LEVEL is a heading depth (1-8) or t for
every level without its own entry.  ATTRS is a face attribute plist;
color values may be given as palette color names.  The attributes are
applied to `org-level-N' and `markdown-header-face-N'.

For example:

  (setq evergarden-headings
        \='((1 :overline t :height 1.4)
          (2 :overline t :height 1.3)
          (3 :overline t :height 1.2)
          (t :height 1.1)))"
  :type '(alist :key-type (choice (integer :tag "Heading level")
                                  (const :tag "Other levels" t))
                :value-type plist)
  :group 'evergarden-themes)

(defcustom evergarden-overrides nil
  "Alist of face overrides, mirroring the Neovim port's `overrides'.

Each element is (FACE . SPEC).  SPEC is either a plist with `:fg', `:bg' and
`:style' keys, or a shorthand list of (FG BG) / (FG BG STYLE).  Colors may
be hex strings or palette color names.  Examples:

  ((default :bg crust)
   (font-lock-keyword-face \"#fddce3\" \"#1d2021\")
   (font-lock-string-face :fg green :style (bold)))"
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

(defun evergarden--color (colors name)
  "Return the hex color for NAME in COLORS.
NAME may be a color symbol, `none' for no color, or nil for no color."
  (cond ((null name) nil)
        ((eq name 'none) nil)
        (t (cdr (assq name colors)))))

(defun evergarden--resolve-value (value colors)
  "Return VALUE with palette color symbols resolved via COLORS.
A symbol naming a palette color becomes its hex string, `none' becomes
nil, and anything else is returned unchanged."
  (cond ((memq value '(nil t)) value)
        ((assq value colors) (cdr (assq value colors)))
        ((eq value 'none) nil)
        (t value)))

(defun evergarden--resolve-attrs (attrs colors)
  "Resolve palette color symbols in the face plist ATTRS via COLORS.
Keys whose value resolves to nil are dropped."
  (let (resolved)
    (while attrs
      (let ((value (evergarden--resolve-value (cadr attrs) colors)))
        (when value
          (setq resolved (plist-put resolved (car attrs) value))))
      (setq attrs (cddr attrs)))
    resolved))

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

(defun evergarden--hex-to-rgb (hex)
  "Return (R G B) as floats between 0 and 1 for a #rrggbb string HEX."
  (let ((hex (if (string-prefix-p "#" hex) (substring hex 1) hex)))
    (list (/ (string-to-number (substring hex 0 2) 16) 255.0)
          (/ (string-to-number (substring hex 2 4) 16) 255.0)
          (/ (string-to-number (substring hex 4 6) 16) 255.0))))

(defun evergarden--blend (fg bg alpha)
  "Blend FG into BG by ALPHA (a number between 0 and 1)."
  (let ((a (evergarden--hex-to-rgb fg))
        (b (evergarden--hex-to-rgb bg)))
    (apply #'format "#%02x%02x%02x"
           (cl-mapcar (lambda (x y)
                        (round (* 255 (+ (* x alpha) (* y (- 1 alpha))))))
                      a b))))

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
    (cl-labels ((col (name) (cdr (assq name colors)))
                (attrs (fg bg &optional style extra)
                       (evergarden--attrs fg bg style extra))
                (alt-attrs (style fg bg alt-fg alt-bg)
                           ;; The Neovim port's `vary_reverse': a `reverse'
                           ;; style selects the alternate spec, not a swap.
                           (if (memq 'reverse style)
                               (attrs alt-fg alt-bg)
                             (attrs fg bg (delq 'reverse style))))
                (diff-bg (role alpha)
                         (evergarden--blend (plist-get diff role) (col 'base) alpha))
                (error-bg (alpha)
                          (evergarden--blend (plist-get diag :error) (col 'base) alpha)))
      (append
       ;; Canvas and chrome.
       (list
        (cons 'default (attrs (col 'text)
                          (unless evergarden-transparent-background (col 'base))))
        (cons 'cursor (attrs (col 'crust) (plist-get theme :cursor)))
        (cons 'region (attrs nil (col 'surface1)))
        (cons 'hl-line (attrs nil (col 'surface0)))
        (cons 'fringe (attrs (col 'overlay1)
                         (unless evergarden-transparent-background (col 'base))))
        (cons 'line-number (attrs (col 'surface2) nil))
        (cons 'line-number-current-line (attrs (col 'overlay2) nil))
        (cons 'window-divider
              (attrs (if evergarden-transparent-background (col 'surface0) (col 'surface1)) nil))
        (cons 'vertical-border (attrs (col 'surface1) nil))
        (cons 'mode-line
              (attrs (plist-get sl-active :fg)
                 (unless evergarden-transparent-background (plist-get sl-active :bg))))
        (cons 'mode-line-inactive
              (attrs (plist-get sl-inactive :fg)
                 (unless evergarden-transparent-background (plist-get sl-inactive :bg))))
        (cons 'header-line (attrs (col 'subtext0) nil))
        (cons 'tab-bar (attrs (col 'overlay1) (col 'surface0)))
        (cons 'tab-bar-tab
              (alt-attrs evergarden-style-tabline
                         (col 'subtext1) (col 'surface0) (col 'crust) accent))
        (cons 'tab-bar-tab-group-current
              (if (memq 'reverse evergarden-style-tabline)
                  (attrs (col 'crust) accent '(bold))
                (attrs (col 'subtext1) (col 'surface1) '(bold))))
        (cons 'tab-bar-tab-inactive (attrs (col 'overlay1) (col 'surface0)))
        (cons 'tab-line (attrs (col 'overlay1) (col 'surface0)))
        (cons 'tab-line-tab
              (alt-attrs evergarden-style-tabline
                         (col 'subtext1) (col 'surface0) (col 'crust) accent))
        (cons 'tab-line-tab-current
              (if (memq 'reverse evergarden-style-tabline)
                  (attrs (col 'crust) accent)
                (attrs (col 'subtext1) (col 'surface1))))
        (cons 'tab-line-tab-inactive (attrs (col 'overlay1) (col 'surface0)))
        (cons 'minibuffer-prompt (attrs (col 'subtext0) nil))
        (cons 'shadow (attrs (col 'overlay1) nil))
        (cons 'link (attrs (col 'blue) nil nil '(:underline t)))
        (cons 'highlight (attrs nil (col 'surface0)))
        (cons 'tooltip (attrs (col 'text) (or float (col 'mantle))))
        (cons 'show-paren-match (attrs (col 'orange) nil)))

       ;; Search.  The Neovim port resolves these through `vary_reverse': a
       ;; `reverse' style selects the alternate spec rather than swapping.
       (list
        (cons 'isearch
              (alt-attrs evergarden-style-search search nil
                         (if light (col 'text) (col 'crust)) search))
        (cons 'isearch-fail (attrs (col 'crust) (col 'red)))
        (cons 'lazy-highlight
              (alt-attrs evergarden-style-search (col 'surface1) nil
                         (col 'subtext1) (col 'surface1)))
        (cons 'query-replace
              (alt-attrs evergarden-style-incsearch incsearch nil
                         (if light (col 'text) (col 'crust)) incsearch)))

       ;; Completion and pickers.
       (list
        (cons 'completions-annotations (attrs (plist-get syntax :annotation) nil))
        (cons 'completions-common-part (attrs incsearch nil))
        (cons 'completions-first-difference (attrs nil nil '(bold)))
        (cons 'company-tooltip (attrs (col 'text) completion))
        (cons 'company-tooltip-selection
              (attrs nil selected selected-style))
        (cons 'company-tooltip-common (attrs incsearch completion))
        (cons 'company-tooltip-annotation
              (attrs (plist-get syntax :annotation) completion))
        (cons 'corfu-default (attrs (col 'text) completion))
        (cons 'corfu-current (attrs nil selected selected-style))
        (cons 'corfu-annotations (attrs (plist-get syntax :annotation) completion))
        (cons 'corfu-border (attrs (if evergarden-float-solid-border completion (col 'surface0))
                               completion))
        (cons 'vertico-current (attrs accent (col 'surface0) '(bold)))
        (cons 'ivy-current-match (attrs accent (col 'surface0) '(bold)))
        (cons 'helm-selection (attrs accent (col 'surface0) '(bold)))
        (cons 'helm-match (attrs incsearch nil)))

       ;; Diffs.
       (list
        (cons 'diff-added (attrs nil (diff-bg :add 0.16)))
        (cons 'diff-removed (attrs nil (diff-bg :delete 0.16)))
        (cons 'diff-changed (attrs nil (diff-bg :change 0.08)))
        (cons 'diff-refine-added
              (attrs nil (diff-bg :add 0.16)))
        (cons 'diff-refine-removed
              (attrs nil (diff-bg :delete 0.16)))
        (cons 'diff-refine-changed
              (attrs nil (diff-bg :change 0.16)))
        (cons 'diff-header (attrs (col 'text) nil))
        (cons 'diff-file-header (attrs (col 'text) nil '(bold))))

       ;; Messages, diagnostics and spelling.
       (list
        (cons 'error (attrs (plist-get diag :error) nil))
        (cons 'warning (attrs (plist-get diag :warn) nil))
        (cons 'success (attrs (plist-get diag :ok) nil))
        (cons 'flycheck-error
              (attrs (plist-get diag :error) nil evergarden-style-diagnostics))
        (cons 'flycheck-warning
              (attrs (plist-get diag :warn) nil evergarden-style-diagnostics))
        (cons 'flycheck-info
              (attrs (plist-get diag :info) nil evergarden-style-diagnostics))
        (cons 'flycheck-fringe-error (attrs (plist-get diag :error) sign))
        (cons 'flycheck-fringe-warning (attrs (plist-get diag :warn) sign))
        (cons 'flycheck-fringe-info (attrs (plist-get diag :info) sign))
        (cons 'flymake-error
              (attrs (plist-get diag :error) nil evergarden-style-diagnostics))
        (cons 'flymake-warning
              (attrs (plist-get diag :warn) nil evergarden-style-diagnostics))
        (cons 'flymake-note
              (attrs (plist-get diag :info) nil evergarden-style-diagnostics))
        (cons 'eglot-inlay-hint-face (attrs (col 'overlay1) nil))
        (cons 'lsp-inlay-hint-face (attrs (col 'overlay1) nil))
        (cons 'eldoc-highlight-function-argument (attrs nil nil '(bold)))
        (cons 'flyspell-incorrect (attrs (col 'red) nil evergarden-style-spell))
        (cons 'flyspell-duplicate (attrs (col 'aqua) nil evergarden-style-spell)))

       ;; Syntax.
       (list
        (cons 'font-lock-keyword-face
              (attrs (plist-get syntax :keyword) nil evergarden-style-keyword))
        (cons 'font-lock-type-face
              (attrs (plist-get syntax :type) nil evergarden-style-types))
        (cons 'font-lock-function-name-face (attrs (plist-get syntax :func) nil))
        (cons 'font-lock-variable-name-face (attrs (plist-get syntax :identifier) nil))
        (cons 'font-lock-constant-face (attrs (plist-get syntax :constant) nil))
        (cons 'font-lock-builtin-face (attrs (col 'orange) nil))
        (cons 'font-lock-string-face (attrs (plist-get syntax :string) nil))
        (cons 'font-lock-doc-face (attrs (col 'skye) nil))
        (cons 'font-lock-comment-face
              (attrs comment nil evergarden-style-comment))
        (cons 'font-lock-comment-delimiter-face
              (attrs comment nil evergarden-style-comment))
        (cons 'font-lock-preprocessor-face (attrs (plist-get syntax :annotation) nil))
        (cons 'font-lock-negation-char-face (attrs (col 'orange) nil))
        (cons 'font-lock-warning-face (attrs (col 'yellow) nil '(bold)))
        (cons 'font-lock-operator-face (attrs (plist-get syntax :operator) nil))
        (cons 'font-lock-property-face (attrs (plist-get syntax :property) nil))
        (cons 'font-lock-bracket-face (attrs (plist-get syntax :context) nil))
        (cons 'font-lock-delimiter-face (attrs (plist-get syntax :context) nil))
        (cons 'font-lock-escape-face (attrs (col 'yellow) nil))
        (cons 'font-lock-number-face (attrs (plist-get syntax :constant) nil))
        (cons 'font-lock-function-call-face (attrs (plist-get syntax :func) nil)))

       ;; Markup: org-mode and markdown-mode.  The Neovim port styles
       ;; @markup.strong as aqua bold, @markup.italic as skye italic,
       ;; @markup.raw as overlay1, links and URIs as blue, and headings as
       ;; rainbow1..6 (red, orange, yellow, green, aqua, blue); plain markup
       ;; is Title (cherry).
       (list
        (cons 'org-level-1 (attrs (col 'red) nil '(bold)))
        (cons 'org-level-2 (attrs (col 'orange) nil '(bold)))
        (cons 'org-level-3 (attrs (col 'yellow) nil '(bold)))
        (cons 'org-level-4 (attrs (col 'green) nil '(bold)))
        (cons 'org-level-5 (attrs (col 'aqua) nil '(bold)))
        (cons 'org-level-6 (attrs (col 'blue) nil '(bold)))
        (cons 'org-level-7 (attrs (col 'purple) nil '(bold)))
        (cons 'org-level-8 (attrs (col 'pink) nil '(bold)))
        (cons 'org-document-title (attrs (col 'cherry) nil '(bold)))
        (cons 'org-document-info (attrs (col 'subtext0) nil))
        (cons 'org-document-info-keyword (attrs (col 'overlay1) nil))
        (cons 'org-todo (attrs (col 'crust) (col 'aqua) '(bold)))
        (cons 'org-done (attrs (col 'green) nil '(bold)))
        (cons 'org-tag (attrs (col 'overlay1) nil))
        (cons 'org-priority (attrs (col 'red) nil '(bold)))
        (cons 'org-link (attrs (col 'blue) nil nil '(:underline t)))
        (cons 'org-footnote (attrs (col 'blue) nil nil '(:underline t)))
        (cons 'org-code (attrs (col 'overlay1) nil))
        (cons 'org-verbatim (attrs (col 'overlay1) nil))
        (cons 'org-block (attrs (col 'overlay1) nil))
        (cons 'org-block-begin-line (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'org-block-end-line (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'org-quote (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'org-table (attrs (col 'subtext0) nil))
        (cons 'org-date (attrs (col 'skye) nil))
        (cons 'org-scheduled (attrs (col 'green) nil))
        (cons 'org-scheduled-today (attrs (col 'green) nil '(bold)))
        (cons 'org-scheduled-previously (attrs (col 'yellow) nil))
        (cons 'org-upcoming-deadline (attrs (col 'yellow) nil))
        (cons 'org-deadline (attrs (col 'red) nil))
        (cons 'org-warning (attrs (col 'yellow) nil '(bold)))
        (cons 'org-meta-line (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'org-special-keyword (attrs (col 'overlay2) nil))
        (cons 'org-drawer (attrs (col 'overlay1) nil))
        (cons 'org-property-value (attrs (col 'subtext0) nil))
        (cons 'org-ellipsis (attrs (col 'overlay0) nil))
        (cons 'org-hide (attrs (col 'base) nil))
        (cons 'org-archived (attrs (col 'overlay0) nil))
        (cons 'org-checkbox (attrs nil nil '(bold)))
        (cons 'org-checkbox-statistics-todo (attrs (col 'red) nil '(bold)))
        (cons 'org-checkbox-statistics-done (attrs (col 'green) nil '(bold)))
        (cons 'org-agenda-structure (attrs (col 'cherry) nil '(bold)))
        (cons 'org-agenda-date (attrs (col 'skye) nil))
        (cons 'org-agenda-date-today (attrs accent nil '(bold)))
        (cons 'org-agenda-date-weekend (attrs (col 'overlay1) nil))
        (cons 'org-agenda-done (attrs (col 'green) nil))
        (cons 'org-agenda-dimmed-todo-face (attrs (col 'overlay0) nil))
        (cons 'org-agenda-current-time (attrs (col 'cherry) nil))
        (cons 'markdown-header-face (attrs (col 'cherry) nil '(bold)))
        (cons 'markdown-header-face-1 (attrs (col 'red) nil '(bold)))
        (cons 'markdown-header-face-2 (attrs (col 'orange) nil '(bold)))
        (cons 'markdown-header-face-3 (attrs (col 'yellow) nil '(bold)))
        (cons 'markdown-header-face-4 (attrs (col 'green) nil '(bold)))
        (cons 'markdown-header-face-5 (attrs (col 'aqua) nil '(bold)))
        (cons 'markdown-header-face-6 (attrs (col 'blue) nil '(bold)))
        (cons 'markdown-header-delimiter-face (attrs (col 'overlay2) nil))
        (cons 'markdown-bold-face (attrs (col 'aqua) nil '(bold)))
        (cons 'markdown-italic-face (attrs (col 'skye) nil '(italic)))
        (cons 'markdown-link-face (attrs (col 'blue) nil nil '(:underline t)))
        (cons 'markdown-url-face (attrs (col 'blue) nil nil '(:underline t)))
        (cons 'markdown-inline-code-face (attrs (col 'overlay1) nil))
        (cons 'markdown-code-face (attrs (col 'overlay1) nil))
        (cons 'markdown-pre-face (attrs (col 'overlay1) nil))
        (cons 'markdown-list-face (attrs (col 'overlay1) nil))
        (cons 'markdown-blockquote-face (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'markdown-markup-face (attrs (col 'overlay1) nil))
        (cons 'markdown-language-keyword-face (attrs (col 'cherry) nil))
        (cons 'markdown-footnote-marker-face (attrs (col 'overlay1) nil))
        (cons 'markdown-metadata-key-face (attrs (col 'skye) nil))
        (cons 'markdown-metadata-value-face (attrs (col 'subtext0) nil))
        (cons 'markdown-table-face (attrs (col 'subtext0) nil))
        (cons 'markdown-hr-face (attrs (col 'overlay0) nil))
        (cons 'markdown-comment-face (attrs (col 'overlay2) nil evergarden-style-comment))
        (cons 'markdown-html-tag-name-face (attrs (col 'green) nil))
        (cons 'markdown-html-attr-name-face (attrs (col 'skye) nil))
        (cons 'markdown-html-attr-value-face (attrs (col 'lime) nil))
        (cons 'markdown-html-entity-face (attrs (col 'aqua) nil)))

       ;; Git and version control.  The Neovim gitsigns integration colors
       ;; the sign column with the diff roles, and magit follows the same
       ;; roles wherever it has an equivalent.
       (list
        (cons 'diff-hl-insert (attrs (plist-get diff :add) sign))
        (cons 'diff-hl-change (attrs (plist-get diff :change) sign))
        (cons 'diff-hl-delete (attrs (plist-get diff :delete) sign))
        (cons 'diff-hl-unknown (attrs (col 'overlay0) sign))
        (cons 'git-gutter:added (attrs (plist-get diff :add) sign))
        (cons 'git-gutter:modified (attrs (plist-get diff :change) sign))
        (cons 'git-gutter:deleted (attrs (plist-get diff :delete) sign))
        (cons 'smerge-upper
              (attrs nil (diff-bg :delete 0.16)))
        (cons 'smerge-lower
              (attrs nil (diff-bg :add 0.16)))
        (cons 'smerge-base
              (attrs nil (diff-bg :change 0.16)))
        (cons 'smerge-markers (attrs (col 'overlay1) (col 'surface0)))
        (cons 'smerge-refined-added
              (attrs nil (diff-bg :add 0.32)))
        (cons 'smerge-refined-removed
              (attrs nil (diff-bg :delete 0.32)))
        (cons 'smerge-refined-changed
              (attrs nil (diff-bg :change 0.32)))
        (cons 'magit-branch-local (attrs (col 'skye) nil))
        (cons 'magit-branch-remote (attrs (col 'green) nil))
        (cons 'magit-branch-current (attrs accent nil nil '(:underline t)))
        (cons 'magit-tag (attrs (col 'yellow) nil))
        (cons 'magit-hash (attrs (col 'overlay1) nil))
        (cons 'magit-dimmed (attrs (col 'overlay1) nil))
        (cons 'magit-cherry-equivalent (attrs (col 'pink) nil))
        (cons 'magit-cherry-unmatched (attrs (col 'aqua) nil))
        (cons 'magit-keyword (attrs (col 'pink) nil))
        (cons 'magit-keyword-squash (attrs (col 'yellow) nil))
        (cons 'magit-log-author (attrs (col 'skye) nil))
        (cons 'magit-log-date (attrs (col 'overlay1) nil))
        (cons 'magit-section-heading (attrs (col 'cherry) nil '(bold)))
        (cons 'magit-section-heading-selection (attrs accent nil '(bold)))
        (cons 'magit-section-highlight (attrs nil (col 'surface0)))
        (cons 'magit-diff-file-heading (attrs (col 'text) nil '(bold)))
        (cons 'magit-diff-hunk-heading (attrs (col 'overlay1) (col 'surface0)))
        (cons 'magit-diff-hunk-heading-highlight (attrs (col 'subtext0) (col 'surface1)))
        (cons 'magit-diff-added
              (attrs nil (diff-bg :add 0.16)))
        (cons 'magit-diff-added-highlight
              (attrs nil (diff-bg :add 0.32)))
        (cons 'magit-diff-removed
              (attrs nil (diff-bg :delete 0.16)))
        (cons 'magit-diff-removed-highlight
              (attrs nil (diff-bg :delete 0.32)))
        (cons 'magit-diff-context (attrs (col 'overlay1) nil))
        (cons 'magit-diff-context-highlight (attrs (col 'subtext0) (col 'surface0)))
        (cons 'magit-process-ok (attrs (plist-get diag :ok) nil))
        (cons 'magit-process-ng (attrs (plist-get diag :error) nil)))

       ;; File trees and directories (nvimtree and neotree).
       (list
        (cons 'dired-directory (attrs (col 'overlay2) nil))
        (cons 'dired-header (attrs (col 'cherry) nil '(bold)))
        (cons 'dired-marked (attrs (col 'crust) accent '(bold)))
        (cons 'dired-flagged (attrs (plist-get diag :error) nil))
        (cons 'dired-symlink (attrs (col 'pink) nil))
        (cons 'dired-broken-link (attrs (plist-get diag :error) nil))
        (cons 'neo-dir-link-face (attrs (col 'overlay2) nil))
        (cons 'neo-file-link-face (attrs (col 'subtext1) nil))
        (cons 'neo-root-dir-face (attrs (col 'pink) nil '(bold)))
        (cons 'neo-header-face (attrs (col 'cherry) nil '(bold)))
        (cons 'neo-banner-face (attrs (col 'cherry) nil))
        (cons 'neo-button-face (attrs (col 'subtext0) nil))
        (cons 'neo-expand-btn-face (attrs (col 'overlay1) nil))
        (cons 'neo-vc-added-face (attrs (col 'blue) nil))
        (cons 'neo-vc-edited-face (attrs (col 'yellow) nil))
        (cons 'neo-vc-removed-face (attrs (plist-get diag :error) nil))
        (cons 'neo-vc-conflict-face (attrs (col 'red) nil '(bold)))
        (cons 'neo-vc-ignored-face (attrs (col 'overlay0) nil))
        (cons 'neo-vc-unregistered-face (attrs (col 'skye) nil))
        (cons 'neo-vc-up-to-date-face (attrs (col 'overlay1) nil))
        (cons 'treemacs-directory-face (attrs (col 'overlay2) nil))
        (cons 'treemacs-directory-collapsed-face (attrs (col 'overlay2) nil))
        (cons 'treemacs-file-face (attrs (col 'subtext1) nil))
        (cons 'treemacs-root-face (attrs (col 'pink) nil '(bold)))
        (cons 'treemacs-tags-face (attrs (col 'subtext0) nil))
        (cons 'treemacs-git-added-face (attrs (col 'blue) nil))
        (cons 'treemacs-git-modified-face (attrs (col 'yellow) nil))
        (cons 'treemacs-git-renamed-face (attrs (plist-get diag :error) nil))
        (cons 'treemacs-git-untracked-face (attrs (col 'skye) nil))
        (cons 'treemacs-git-ignored-face (attrs (col 'overlay0) nil))
        (cons 'treemacs-git-conflict-face (attrs (col 'red) nil '(bold)))
        (cons 'treemacs-git-unmodified-face (attrs (col 'subtext1) nil))
        (cons 'treemacs-git-commit-diff-face (attrs (col 'aqua) nil))
        (cons 'treemacs-marked-file-face (attrs (col 'crust) accent '(bold)))
        (cons 'treemacs-hl-line-face (attrs nil (col 'surface0)))
        (cons 'treemacs-window-background-face
              (attrs nil (unless evergarden-transparent-background (col 'base))))
        (cons 'treemacs-on-success-pulse-face (attrs nil (plist-get diag :ok)))
        (cons 'treemacs-on-failure-pulse-face (attrs nil (plist-get diag :error)))
        (cons 'treemacs-fringe-indicator-face (attrs (col 'overlay1) nil))
        (cons 'treemacs-async-loading-face (attrs (col 'overlay1) nil))
        (cons 'treemacs-header-button-face (attrs (col 'cherry) nil))
        (cons 'treemacs-help-title-face (attrs (col 'cherry) nil '(bold)))
        (cons 'treemacs-help-column-face (attrs (col 'subtext0) nil)))

       ;; which-key and rainbow-delimiters.
       (list
        (cons 'which-key-key-face (attrs (col 'text) nil))
        (cons 'which-key-separator-face (attrs (col 'overlay0) nil))
        (cons 'which-key-group-description-face (attrs (col 'subtext0) nil))
        (cons 'which-key-command-description-face (attrs (col 'subtext0) nil))
        (cons 'which-key-local-map-description-face (attrs (col 'subtext0) nil))
        (cons 'which-key-note-face (attrs (col 'overlay0) nil))
        (cons 'which-key-special-key-face (attrs accent nil '(bold)))
        (cons 'rainbow-delimiters-depth-1-face (attrs (col 'red) nil))
        (cons 'rainbow-delimiters-depth-2-face (attrs (col 'yellow) nil))
        (cons 'rainbow-delimiters-depth-3-face (attrs (col 'blue) nil))
        (cons 'rainbow-delimiters-depth-4-face (attrs (col 'orange) nil))
        (cons 'rainbow-delimiters-depth-5-face (attrs (col 'green) nil))
        (cons 'rainbow-delimiters-depth-6-face (attrs (col 'pink) nil))
        (cons 'rainbow-delimiters-depth-7-face (attrs (col 'aqua) nil))
        (cons 'rainbow-delimiters-depth-8-face (attrs (col 'purple) nil))
        (cons 'rainbow-delimiters-depth-9-face (attrs (col 'cherry) nil))
        (cons 'rainbow-delimiters-base-face (attrs (col 'text) nil))
        (cons 'rainbow-delimiters-base-error-face (attrs (col 'red) nil))
        (cons 'rainbow-delimiters-unmatched-face (attrs (col 'red) nil '(bold)))
        (cons 'rainbow-delimiters-mismatched-face (attrs (col 'red) nil '(bold)))
        ;; nvim's indent-blankline: surface0 guides, scope in green.
        (cons 'highlight-indent-guides-odd-face (attrs nil (col 'surface0)))
        (cons 'highlight-indent-guides-even-face (attrs nil (col 'surface0)))
        (cons 'highlight-indent-guides-character-face (attrs (col 'surface0) nil))
        (cons 'highlight-indent-guides-stack-character-face (attrs (col 'surface1) nil))
        (cons 'highlight-indent-guides-stack-odd-face (attrs nil (col 'surface1)))
        (cons 'highlight-indent-guides-stack-even-face (attrs nil (col 'surface1)))
        (cons 'highlight-indent-guides-top-character-face (attrs (col 'green) nil))
        (cons 'highlight-indent-guides-top-odd-face (attrs nil (col 'surface1)))
        (cons 'highlight-indent-guides-top-even-face (attrs nil (col 'surface1))))

       ;; Miscellaneous editing chrome.
       (list
        (cons 'match (attrs nil (col 'surface1)))
        (cons 'secondary-selection (attrs nil (col 'surface0)))
        (cons 'comint-highlight-prompt (attrs (col 'subtext0) nil))
        (cons 'compilation-error (attrs (plist-get diag :error) nil))
        (cons 'compilation-warning (attrs (plist-get diag :warn) nil))
        (cons 'compilation-info (attrs (plist-get diag :info) nil))
        (cons 'compilation-line-number (attrs (col 'overlay1) nil))
        (cons 'compilation-column-number (attrs (col 'overlay1) nil))
        (cons 'compilation-mode-line-exit (attrs (plist-get diag :ok) nil '(bold)))
        (cons 'compilation-mode-line-fail (attrs (plist-get diag :error) nil '(bold)))
        (cons 'compilation-mode-line-run (attrs (plist-get diag :warn) nil '(bold)))
        (cons 'trailing-whitespace
              (attrs nil (error-bg 0.16)))
        (cons 'whitespace-tab (attrs (col 'surface1) nil))
        (cons 'whitespace-space (attrs (col 'surface1) nil))
        (cons 'whitespace-trailing
              (attrs nil (error-bg 0.16))))

       ;; Doom workspaces.  The workspace tabs that `+workspace/display'
       ;; shows in the echo area use their own faces; without these they
       ;; inherit `highlight' and the selected tab is barely visible.
       (list
        (cons '+workspace-tab-selected-face
              (if (memq 'reverse evergarden-style-tabline)
                  (attrs (col 'crust) accent)
                (attrs (col 'subtext1) (col 'surface1))))
        (cons '+workspace-tab-face (attrs (col 'overlay1) nil)))
       (list
        (cons 'doom-modeline-bar (attrs nil accent))
        (cons 'doom-modeline-buffer-file (attrs (col 'text) nil '(bold)))
        (cons 'doom-modeline-buffer-path (attrs (col 'subtext0) nil))
        (cons 'doom-modeline-buffer-major-mode (attrs (col 'green) nil))
        (cons 'doom-modeline-buffer-modified (attrs (col 'yellow) nil))
        (cons 'doom-modeline-buffer-minor-mode (attrs (col 'overlay1) nil))
        (cons 'doom-modeline-project-dir (attrs (col 'subtext0) nil))
        (cons 'doom-modeline-project-root-dir (attrs (col 'skye) nil))
        (cons 'doom-modeline-info (attrs (plist-get diag :ok) nil))
        (cons 'doom-modeline-warning (attrs (plist-get diag :warn) nil))
        (cons 'doom-modeline-error (attrs (plist-get diag :error) nil))
        (cons 'doom-modeline-urgent (attrs (plist-get diag :error) nil '(bold)))
        (cons 'doom-modeline-debug (attrs (col 'cherry) nil))
        (cons 'doom-modeline-notification (attrs (col 'blue) nil))
        (cons 'doom-modeline-evil-normal-state (attrs (col 'blue) nil '(bold)))
        (cons 'doom-modeline-evil-insert-state (attrs (col 'green) nil '(bold)))
        (cons 'doom-modeline-evil-visual-state (attrs (col 'yellow) nil '(bold)))
        (cons 'doom-modeline-evil-emacs-state (attrs (col 'purple) nil '(bold)))
        (cons 'doom-modeline-evil-motion-state (attrs (col 'purple) nil '(bold)))
        (cons 'doom-modeline-evil-operator-state (attrs (col 'blue) nil '(bold))))

       ;; ANSI terminal colors, mirroring the Neovim port.
       (list
        (cons 'ansi-color-black (attrs (col 'surface1) nil))
        (cons 'ansi-color-red (attrs (col 'red) nil))
        (cons 'ansi-color-green (attrs (col 'green) nil))
        (cons 'ansi-color-yellow (attrs (col 'yellow) nil))
        (cons 'ansi-color-blue (attrs (col 'blue) nil))
        (cons 'ansi-color-magenta (attrs (col 'pink) nil))
        (cons 'ansi-color-cyan (attrs (col 'aqua) nil))
        (cons 'ansi-color-white (attrs (col 'subtext0) nil))
        (cons 'ansi-color-bright-black (attrs (col 'overlay1) nil))
        (cons 'ansi-color-bright-red (attrs (col 'red) nil))
        (cons 'ansi-color-bright-green (attrs (col 'green) nil))
        (cons 'ansi-color-bright-yellow (attrs (col 'yellow) nil))
        (cons 'ansi-color-bright-blue (attrs (col 'blue) nil))
        (cons 'ansi-color-bright-magenta (attrs (col 'pink) nil))
        (cons 'ansi-color-bright-cyan (attrs (col 'aqua) nil))
        (cons 'ansi-color-bright-white (attrs (col 'subtext1) nil)))))))

(defun evergarden--apply-override (face attrs colors)
  "Apply the user's `evergarden-overrides' entry for FACE to ATTRS.
Color values may be hex strings or palette color names, resolved via
COLORS."
  (let ((override (cdr (assq face evergarden-overrides))))
    (cond
     ((null override) attrs)
     ;; Plist form: (:fg surface1 :bg crust :style (bold))
     ((keywordp (car override))
      (let* ((fg (evergarden--resolve-value (plist-get override :fg) colors))
             (bg (evergarden--resolve-value (plist-get override :bg) colors))
             (style (plist-get override :style))
             (attrs (copy-sequence attrs)))
        (when fg (setq attrs (plist-put attrs :foreground fg)))
        (when bg (setq attrs (plist-put attrs :background bg)))
        (when style
          (setq attrs (append (evergarden--style-attrs style (plist-get attrs :foreground))
                              attrs)))
        attrs))
     ;; Shorthand: (FG BG) / (FG BG STYLE)
     (t
      (let ((fg (evergarden--resolve-value (nth 0 override) colors))
            (bg (evergarden--resolve-value (nth 1 override) colors))
            (attrs (copy-sequence attrs)))
        (when fg (setq attrs (plist-put attrs :foreground fg)))
        (when bg (setq attrs (plist-put attrs :background bg)))
        (when (nth 2 override)
          (setq attrs (append (evergarden--style-attrs (nth 2 override)
                                                       (plist-get attrs :foreground))
                              attrs)))
        attrs)))))

(defun evergarden--heading-attrs (face attrs colors)
  "Return ATTRS extended by the `evergarden-headings' entry for FACE.
Heading faces are `org-level-N' and `markdown-header-face-N'; levels
without their own entry fall back to the `t' entry."
  (let ((name (symbol-name face)) level)
    (when (string-match
           "\\`\\(?:org-level\\|markdown-header-face\\)-\\([0-9]+\\)\\'"
           name)
      (setq level (string-to-number (match-string 1 name))))
    (if level
        (append attrs
                (evergarden--resolve-attrs
                 (or (cdr (assq level evergarden-headings))
                     (cdr (assq t evergarden-headings)))
                 colors))
      attrs)))

(defun evergarden--face-specs (flavor accent)
  "Return `custom-theme-set-faces' specs for FLAVOR and ACCENT."
  (let* ((theme (evergarden--theme flavor accent))
         (colors (plist-get theme :colors)))
    (mapcar
     (lambda (cell)
       (let* ((face (car cell))
              (attrs (evergarden--heading-attrs face (cdr cell) colors)))
         (list face (list (cons t (evergarden--apply-override face attrs colors))))))
     (evergarden--faces theme))))

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
       (setq evergarden-flavor ',flavor
             evergarden-accent ',accent)
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

(defun evergarden--theme-parts (theme)
  "Return (FLAVOR ACCENT) if THEME names an Evergarden theme, else nil."
  (let ((parts (split-string (symbol-name theme) "-")))
    (when (and (= (length parts) 3)
               (string= (nth 0 parts) "evergarden")
               (memq (intern (nth 1 parts)) evergarden--flavors)
               (memq (intern (nth 2 parts)) evergarden--accents))
      (list (intern (nth 1 parts)) (intern (nth 2 parts))))))

(defun evergarden--dark-theme-p (theme)
  "Return non-nil if THEME names a dark Evergarden theme."
  (and (symbolp theme)
       (let ((parts (evergarden--theme-parts theme)))
         (and parts (evergarden--dark-p (car parts))))))

(defun evergarden--sync-doom-theme (theme)
  "Return the value `doom-theme' should take after THEME is loaded.
When `doom-theme' is a dark/light pair, only the half that is an
Evergarden theme with the same darkness as THEME is replaced, so Doom
keeps selecting for the system appearance.  Any other value is
replaced by THEME."
  (if (and (consp doom-theme) (evergarden--theme-parts theme))
      (let ((dark (evergarden--dark-theme-p theme)))
        (cond
         ((eq (evergarden--dark-theme-p (car doom-theme)) dark)
          (cons theme (cdr doom-theme)))
         ((eq (evergarden--dark-theme-p (cdr doom-theme)) dark)
          (cons (car doom-theme) theme))
         (t theme)))
    theme))

(defun evergarden--label (flavor accent)
  "Return a human-readable label for FLAVOR and ACCENT."
  (format "%s · %s (%s)"
          (evergarden--flavor-name flavor) accent
          (evergarden--theme-symbol flavor accent)))

(defun evergarden--cycle (list value delta &optional test)
  "Return the element of LIST DELTA positions after VALUE, wrapping.
TEST is the equality test used to find VALUE, defaulting to `eql'."
  (let* ((n (length list))
         (i (or (cl-position value list :test (or test #'eql)) 0)))
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
Loading the theme keeps `evergarden-flavor' and `evergarden-accent' in
sync, disables any other Evergarden theme and, inside Doom Emacs, keeps
`doom-theme' in sync."
  (interactive (list (evergarden--read-flavor) (evergarden--read-accent)))
  (let ((theme (evergarden--theme-symbol flavor accent)))
    (dolist (enabled custom-enabled-themes)
      (when (and (not (eq enabled theme))
                 (string-prefix-p "evergarden-" (symbol-name enabled)))
        (disable-theme enabled)))
    (load-theme theme t)
    (when (boundp 'doom-theme)
      (setq doom-theme (evergarden--sync-doom-theme theme)))
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
     (let ((next (evergarden--cycle (evergarden--combos)
                                    (cons evergarden-flavor evergarden-accent)
                                    delta #'equal)))
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
