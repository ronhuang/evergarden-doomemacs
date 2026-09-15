_default:
  @just --list

# Regenerate the palette data and theme files from the Whiskers templates.
build:
  whiskers evergarden.tera
  whiskers evergarden-themes.tera

# Fail if the generated files are out of date.  Used by CI.
check:
  whiskers evergarden.tera --check
  whiskers evergarden-themes.tera --check
