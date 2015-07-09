# Aglio Default Theme

[![Dependency Status](https://img.shields.io/david/danielgtaylor/aglio/olio-theme.svg)](https://david-dm.org/danielgtaylor/aglio) [![Build Status](http://img.shields.io/travis/danielgtaylor/aglio/olio-theme.svg)](https://travis-ci.org/danielgtaylor/aglio) [![Coverage Status](http://img.shields.io/coveralls/danielgtaylor/aglio/olio-theme.svg)](https://coveralls.io/r/danielgtaylor/aglio) [![NPM version](http://img.shields.io/npm/v/aglio-theme-olio.svg)](https://www.npmjs.org/package/aglio-theme-olio) [![License](http://img.shields.io/npm/l/aglio-theme-olio.svg)](https://www.npmjs.org/package/aglio-theme-olio)

This is *Olio*, the default theme engine for [Aglio](https://github.com/danielgtaylor/aglio). It takes an [API Blueprint](http://apiblueprint.org/) AST and renders it into static HTML. Example use:

```bash
$ sudo npm install -g aglio
$ aglio -i blueprint.apib -o MyAPI.html
```

Theme engines for Aglio are described in more detail in the [Aglio documentation]().

## Design Philosophy
Olio is designed from the ground up to be both **fast** and **extensible** while maintaining backward compatibility with most of the original Aglio theme. It uses the following technologies:

* [Less](http://lesscss.org/) to produce CSS
* [Markdown-it](https://github.com/markdown-it/markdown-it#readme) to render Markdown
* [Jade](http://jade-lang.com/) to produce HTML
* [Highlight.js](https://highlightjs.org/) to highlight code snippets

For backward compatibility, Jade templates can continue to use inline Stylus and CoffeeScript.

## Theme Options

Olio comes with a handful of configurable theme options. These are set via the `--theme-XXX` parameter, where `XXX` is one of the following:

Name           | Description
-------------- | ------------------
`condense-nav` | Whether to condense navigation groups to get a better overview of complex APIs (**TODO**).
`full-width`   | Whether to use the full page width or a responsive layout (default is responsive).
`style`        | LESS or CSS to control the layout and style of the document using the variables from below. Can be a path to your own file or one of the following presets: `default`.
`template`     | Jade template to render HTML. Can be a path to your own file or one of the following presets: `default`.
`variables`    | LESS variables that control theme colors, fonts, and spacing. Can be a path to your own file or one of the following presets: `default`, `flatly`.

**Note**: When using this theme programmatically, these options are cased like you would expect in Javascript: `--full-width` becomes `options.themeFullWidth`.

License
=======
Copyright &copy; 2015 Daniel G. Taylor

http://dgt.mit-license.org/
