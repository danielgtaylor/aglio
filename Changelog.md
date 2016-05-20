# 2.2.1 - 2016-05-20

* Bump protagonist version to 1.3.2 to support new features. [#256](https://github.com/danielgtaylor/aglio/pull/256)
* Update required default theme version to [1.6.3](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md#163---2016-05-20).

# 2.2.0 - 2015-10-26

* Support for Node.js 3.x and 4.x. [#183](https://github.com/danielgtaylor/aglio/issues/183)
* Upgraded to [Protagonist](https://github.com/apiaryio/protagonist) version 1.x, which has disabled the JSON Schema generation from MSON until some bugs can be worked out.

# 2.1.1 - 2015-09-14

* Fix the default include path behavior when outputting a file to use the basename of the input file rather than `process.cwd()`. Also updates documentation to mention this behavior and option. [#166](https://github.com/danielgtaylor/aglio/issues/166)

# 2.1.0 - 2015-09-11

* Add a `--include-path` option to set the path for relative includes. [#165](https://github.com/danielgtaylor/aglio/pull/165)

# 2.0.4 - 2015-08-14

* Show theme name before loading when given `--verbose` option.
* Update required default theme version to [1.2.0](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md#120---2015-08-14).

# 2.0.3 - 2015-08-12

* Update required default theme version to [1.1.0](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md#110---2015-08-12).
* Readme and example updates.

# 2.0.2 - 2015-08-04

* Update required default theme version to support custom jade templates written for Aglio 1.x.
* Add a `--verbose` output option for errors that displays pretty stack traces.
* Provide more descriptive errors.

# 2.0.1 - 2015-08-03

* Add backward-compatible support for the `aglio` binary to specify a custom layout via the `-t` commandline option. Example: `aglio -i input.apib -t /path/to/my.jade -o output.html`
* Display default theme version when using `aglio --version`.

# 2.0.0 - 2015-07-16
This is a new major version of Aglio, and as such has some breaking changes.
High-level changes in this release:

* Use [Drafter.js](https://github.com/apiaryio/drafter.js) to support [MSON](https://github.com/apiaryio/mson) via generated request/response bodies and schemas.
* Add support for [theme engines](https://github.com/danielgtaylor/aglio#using-custom-themes).
* Use [Olio](https://github.com/danielgtaylor/aglio/tree/olio-theme#readme) as the new default theme engine.
* API and resource group description headers are now included in the navigation bar.
* Server mode can now serve static files, which is useful if your documentation contains images.
* Fixes to how resource and action parameters are handled.

For more detailed information, see the beta releases below.

Effort was taken to prevent backward-incompatible changes. Here is a list of
things that **will break** if you used them in 1.x.

Binary:
* It is no longer possible to list templates (`aglio -l`). You may use `npm list -g | grep aglio-theme` to list all installed theme engine packages instead. Refer to individual theme documentation for possible theme engine options.

Library:
* The `aglio.getTemplates` function has been **removed**.

Templates:
* The multi-page layouts have been **removed**. Please open an issue if you would like to see them in the new theme engine.
* The collapsed navigation layouts have been **removed**. This is now in the default theme and handled automatically based on browser window height.

The following are translated internally and will not break, but are suggested updates:

Binary:
* The `-t` option is now shorthand for `--theme` instead of `--template`.
* The `--full-width` and `--condense-nav` parameters are now `--theme-full-width` and `--theme-condense-nav` in the default theme engine.

Library:
* Passing a string as the options to `render` and `renderFile` will still work if it is a known variant: `default`, `flatly`, `slate`, `cyborg` or one of the collapsed versions of those. If it is a path and the file exists, then it will use it as a custom `themeLayout` option. Otherwise it will set the theme engine name. :dizzy_face:
* You should use `options.theme` instead of `options.template`.
* You should use `options.themeVariables = 'flatly'` to set the color variation.
* You should use `options.themeTemplate = '/path/to/layout.jade'` to set the layout template.

Thank you to all the contributors and testers for helping to make this an awesome release! :beers:

# 2.0.0-beta6 - 2015-07-14
* Update to [olio theme](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md) 0.0.9.

# 2.0.0-beta5 - 2015-07-10
* Fix an issue with included paths when using `--server`.
* Update to [olio theme](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md) 0.0.8.

# 2.0.0-beta4 - 2015-07-10
* Update to [olio theme](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md) 0.0.7.

# 2.0.0-beta3 - 2015-07-09
* Documentation updates.
* Server mode now serves static files if found.
* Add ability to output compiled API Blueprint file instead of HTML.
* Update to [olio theme](https://github.com/danielgtaylor/aglio/blob/olio-theme/Changelog.md) 0.0.6.

# 2.0.0-beta2 - 2015-05-29
* Live update fixes.
* Example fixes.

# 2.0.0-beta1 - 2015-05-28
* Implement theme engine support; depend on the default olio theme.
* Switch to using drafter.js instead of protagonist directly.

# 1.18.0 - 2015-03-31
* Upgrade to [Protagonist] 0.19.0, which adds support for Node.js 0.12.x
  and iojs 1.x.
  ([#77](https://github.com/danielgtaylor/aglio/issues/77))

# 1.17.1 - 2014-12-16
* Switch to [Remarkable](https://github.com/jonschlinkert/remarkable)
  Markdown parser, which is faster and supports the new CommonMark
  specification. [GFM](https://help.github.com/articles/github-flavored-markdown/)
  is supported.
* Fix live reload no longer working with some configurations
  ([#74](https://github.com/danielgtaylor/aglio/issues/74))
* Watch all included files for live reloading.

# 1.17.0 - 2014-12-16
* New logo
* Add support for [including files]
  (https://github.com/danielgtaylor/aglio#including-files)
* Update dependencies (chokidar)

# 1.16.2 - 2014-11-18
* Update dependencies (chokidar, marked, protagonist, stylus)
* Fixes rendering description when headers are not present
  ([#66](https://github.com/danielgtaylor/aglio/pull/66))
* Fixes minor typo
  ([#67](https://github.com/danielgtaylor/aglio/pull/67))

# 1.16.1 - 2014-08-29
* Fixes template js bug related to live reloading.
  ([179ea7e](https://github.com/danielgtaylor/aglio/commit/179ea7e5bf1b37e53b2b034be11eb134a506ffcf))

# 1.16.0 - 2014-08-29
* Fix long choice lists not wrapping
  ([#35](https://github.com/danielgtaylor/aglio/pull/35))
* Fix long hostnames not wrapping
  ([#55](https://github.com/danielgtaylor/aglio/pull/55))
* Add support for live reloading the preview server
  ([#57](https://github.com/danielgtaylor/aglio/pull/57))
* Fix a bug when reading from stdin
  ([#59](https://github.com/danielgtaylor/aglio/pull/59))
* Update dependencies (coffee-script)
* Minor test fixes
