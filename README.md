# Evergarden for GNU Emacs

An [Evergarden](https://evergarden.moe) port for GNU Emacs, packaged as
`evergarden-themes`.

Every flavor and accent combination is registered as a real Emacs theme, and
commands are provided for cycling through them at runtime — no restart and no
config edits needed while you look for the combination you like.

```
4 flavors (winter, fall, spring, summer)
x 12 accents (red, orange, yellow, lime, green, aqua, skye, snow, blue, purple, pink, cherry)
= 48 themes
```

The face mapping follows the official [Neovim port](https://codeberg.org/evergarden/nvim):
syntax colors are fixed per flavor, while the accent drives the cursor, the
active tab, the completion/picker and marked-item selection, and the Doom
modeline bar.

## Install

With Doom Emacs, declare the package and pick a theme:

```elisp
;;; ~/.config/doom/packages.el
(package! evergarden-themes
  :recipe (:host github :repo "ronhuang/evergarden-doomemacs"))

;;; ~/.config/doom/config.el
(setq doom-theme 'evergarden-winter-yellow)
```

`doom-theme` also accepts a dark/light pair, selected by your system
appearance.  Summer is the only light flavor:

```elisp
(setq doom-theme '(evergarden-fall-green . evergarden-summer-green))
```

Without Doom, the themes are ordinary Emacs themes:

```elisp
(require 'evergarden-themes)
(load-theme 'evergarden-winter-yellow t)
```

## Switching at runtime

| Command | Effect |
| --- | --- |
| `evergarden-rotate` | Next of all 48 combinations |
| `evergarden-rotate-reverse` | Previous combination |
| `evergarden-rotate-accent` / `-reverse` | Next/previous accent, same flavor |
| `evergarden-rotate-flavor` / `-reverse` | Next/previous flavor, same accent |
| `evergarden-load-random` | Random flavor and accent |
| `evergarden-select` | Pick a flavor/accent combination |
| `evergarden-select-flavor` / `evergarden-select-accent` | Pick one axis |
| `evergarden-describe` | Echo the current flavor and accent |

Rotation loads the new theme immediately and keeps `doom-theme` in sync when
Doom is present.  A dark/light pair is preserved: only the half whose flavor
darkness matches the new theme is replaced, so system-appearance switching
keeps working.  `evergarden-after-load-theme-hook` runs after each load.

## Customization

Themes are generated from the Neovim port's defaults, and every option can be
overridden per flavor/accent with `custom-theme-set-faces!` or by setting these
before the theme loads:

```elisp
(setq evergarden-flavor 'fall         ; winter | fall | spring | summer
      evergarden-accent 'green        ; any accent above
      evergarden-transparent-background t
      evergarden-cursor-color 'accent ; `accent', `none' or a palette color
      evergarden-sign-color 'none
      evergarden-float-color 'mantle
      evergarden-float-solid-border nil
      evergarden-completion-color 'mantle
      evergarden-completion-selected-color 'surface0
      evergarden-completion-selected-style '(bold)
      evergarden-statusline-active '(:fg subtext0 :bg mantle)
      evergarden-statusline-inactive '(:fg overlay1 :bg mantle)
      evergarden-style-tabline '(reverse)
      evergarden-style-search '(italic reverse)
      evergarden-style-incsearch nil
      evergarden-style-diagnostics '(underline)
      evergarden-style-types '(italic)
      evergarden-style-keyword '(italic)
      evergarden-style-comment '(italic)
      evergarden-style-spell '(underline)
      evergarden-style-disable nil)
```

`evergarden-overrides` mirrors the Neovim port's `overrides`, keyed by Emacs
face name:

```elisp
(setq evergarden-overrides
      '((default :bg "#000000")
        (font-lock-keyword-face "#fddce3" "#1d2021")
        (font-lock-string-face :fg "#9ece6a" :style (bold))))
```

## Face coverage

The themes cover the core UI (default, cursor, region, line numbers, fringe,
mode/header lines, tab bar and tab line, minibuffer, search, links, tooltips),
the syntax faces (`font-lock-*`, including the Emacs 28/29/30 additions such as
`font-lock-operator-face` and `font-lock-property-face`), diagnostics
(flycheck, flymake, eglot), diffs, completion (company, corfu, vertico, ivy,
helm, the built-in `completions-*`), ANSI terminal colors, org-mode and
markdown-mode, magit and smerge, dired, treemacs and neotree, which-key,
rainbow-delimiters, highlight-indent-guides, and the Doom modeline
(`doom-modeline-bar` follows the accent).

The accent is deliberately confined to chrome — cursor, active tab,
completion/picker and marked-item selection, `doom-modeline-bar` — mirroring
the Neovim port; syntax colors are fixed per flavor.

## Development

The palette data (`evergarden-palette-*.el`) and the 48 theme files are
generated from the Evergarden palette by [Whiskers](https://codeberg.org/evergarden/whiskers).
The faces themselves live in `evergarden-themes.el`.

```
just build    # regenerate the generated files
just check    # fail if they are out of date (used by CI)
```

## License

Apache-2.0.  Evergarden itself is by the Evergarden team; this port only maps
its palette onto Emacs faces.
