# Unreleased

* Trim excess whitespace from code examples.
* Use action-specific name when available for resource nav items with a
  single action. This ports over [#75](https://github.com/danielgtaylor/aglio/pull/75)
  to the new Olio theme.
* Fix an issue with loading large blueprints.
* Include description headers for the API and resource groups in the navigation
  menu. This is useful for describing authentication and other items.

# 0.0.7 - 2015-07-10

* Implement a slug cache to stop name collisions.
* Prevent wrapping and overlapping navigation text.
* Add `slate` and `cyborg` color schemes.

# 0.0.6 - 2015-07-09

* Implement navigation item auto-collapse based on window height.
* Documentation updates.
* Update to latest Markdown renderer.

# 0.0.5 - 2015-07-08

* Make navigation item groups collapsible.
* Fix backward compatibility for `--full-width` option.
* Add support for more HTTP verbs (e.g. `HEAD`, `PATCH`).
* Precompile and cache Jade templates.
* Precompile and cache LESS styles.
* Rename `colors` -> `variables`.

# 0.0.4 - 2015-05-29

* Responsive theme adjustments/tweaks
* Fix buttons after live reload
* Prevent JSON parse errors for empty example bodies

# 0.0.3 - 2015-05-28

* Prettify JSON example output of drafter.js.
* Test on more Node/iojs versions.

# 0.0.2 - 2015-05-28

* Various theme fixes.
* Add a `flatly` color scheme.

# 0.0.1 - 2015-02-26

* Use the `self` option with Jade, which significantly speeds up variable lookups.
* Speed request/response highlighting by limiting attempted languages.
* Remove inline `:stylus` in favor of converted CSS.
* Initial release of ported Aglio default theme.
