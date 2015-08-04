# 1.0.4 - 2015-08-04

* Support for Aglio 1.x Jade templates written without using `self`.
* Better error handling by exposing each error level via the error message.

# 1.0.3 - 2015-08-03

* Make cache directory writeable when installed via `sudo`.
  [danielgtaylor/atom-api-blueprint-preview#40](https://github.com/danielgtaylor/atom-api-blueprint-preview/issues/40)

# 1.0.2 - 2015-07-28

* Fix margin around tables to ensure adequate space. [#141](https://github.com/danielgtaylor/aglio/issues/141)

# 1.0.1 - 2015-07-27

* Fix the display of `%`-encoded parameter and attribute choices.
* Fix `%`-encoded value filtering in URI templates and support the `*` operator.
  [#134](https://github.com/danielgtaylor/aglio/issues/134)
* Fix template URI font weight on some browsers.

# 1.0.0 - 2015-07-16

* First stable release.

# 0.0.9 - 2015-07-14

* Compliance with spec on parameter rendering. [#58](https://github.com/danielgtaylor/aglio/issues/58)
* Minor theme color tweaks.
* Make it possible to easily override padding and fonts.
* Fix minor styling issue on Internet Explorer 11.

# 0.0.8 - 2015-07-13

* Better support of URL-encoded parameter names.
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
