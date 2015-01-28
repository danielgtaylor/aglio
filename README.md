# Aglio Default Theme

[![Dependency Status](http://img.shields.io/david/danielgtaylor/aglio-theme-olio.svg?style=flat)](https://david-dm.org/danielgtaylor/aglio-theme-olio) [![Build Status](http://img.shields.io/travis/danielgtaylor/aglio-theme-olio.svg?style=flat)](https://travis-ci.org/danielgtaylor/aglio-theme-olio) [![Coverage Status](http://img.shields.io/coveralls/danielgtaylor/aglio-theme-olio.svg?style=flat)](https://coveralls.io/r/danielgtaylor/aglio-theme-olio) [![NPM version](http://img.shields.io/npm/v/aglio-theme-olio.svg?style=flat)](https://www.npmjs.org/package/aglio-theme-olio) [![License](http://img.shields.io/npm/l/aglio-theme-olio.svg?style=flat)](https://www.npmjs.org/package/aglio-theme-olio)

This is *Olio*, the default theme engine for [Aglio](https://github.com/danielgtaylor/aglio). It takes an [API Blueprint](http://apiblueprint.org/) AST and renders it into static HTML. Example use:

```bash
$ sudo npm install -g aglio
$ aglio -i blueprint.md -o MyAPI.html
```

Theme engines for Aglio are described in more detail in the [Aglio documentation]().

## Design Philosophy
Olio is designed from the ground up to be both **fast** and **extensible** while maintaining backward compatibility with the original Aglio theme. It uses the following technologies:

* Less to produce CSS
* Markdown-it to render Markdown
* Jade to produce HTML
* Highlight.js to highlight code snippets

For backward compatibility, Jade templates can continue to use inline Stylus and CoffeeScript.
