![aglio](https://raw.github.com/danielgtaylor/aglio/master/aglio.png)

[![Dependency Status](http://img.shields.io/david/danielgtaylor/aglio.svg?style=flat)](https://david-dm.org/danielgtaylor/aglio) [![Build Status](http://img.shields.io/travis/danielgtaylor/aglio.svg?style=flat)](https://travis-ci.org/danielgtaylor/aglio) [![Coverage Status](http://img.shields.io/coveralls/danielgtaylor/aglio.svg?style=flat)](https://coveralls.io/r/danielgtaylor/aglio) [![NPM version](http://img.shields.io/npm/v/aglio.svg?style=flat)](https://www.npmjs.org/package/aglio) [![License](http://img.shields.io/npm/l/aglio.svg?style=flat)](https://www.npmjs.org/package/aglio)

Introduction
============

An [API Blueprint](http://apiblueprint.org/) renderer that supports multiple themes and outputs static HTML that can be served by any web host. API Blueprint is a Markdown-based document format that lets you write API descriptions and documentation in a simple and straightforward way. Currently supported is [API Blueprint format 1A](https://github.com/apiaryio/api-blueprint/blob/master/API%20Blueprint%20Specification.md).

Features
--------

 * Fast parsing thanks to [Protagonist](https://github.com/apiaryio/protagonist)
 * Asyncronous processing
 * Multiple templates/themes
 * Support for custom templates written in [Jade](http://jade-lang.com/)
 * Commandline executable `aglio -i api.md -o api.html`
 * Live preview server `aglio -i api.md --server`
 * Node.js library `require('aglio')`
 * Excellent test coverage

Example Output
--------------
Example output is generated from the [example API Blueprint](https://raw.github.com/danielgtaylor/aglio/master/example.md).

 * Default theme: [Single Page](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/default.html) or [Multiple Pages](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/default-multi.html) or [Collapsible](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/default-collapsible.html)
 * Flatly theme: [Single Page](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/flatly.html) or [Multiple Pages](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/flatly-multi.html) or [Collapsible](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/flatly-collapsible.html)
 * Slate theme: [Single Page](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/slate.html) or [Multiple Pages](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/slate-multi.html) or [Collapsible](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/slate-collapsible.html)
 * Cyborg theme: [Single Page](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/cyborg.html) or [Multiple Pages](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/cyborg-multi.html) or [Collapsible](http://htmlpreview.github.io/?https://raw.githubusercontent.com/danielgtaylor/aglio/blob/master/examples/cyborg-collapsible.html)

Installation & Usage
====================
There are two ways to use aglio: as an executable or as a library for Node.js.

Executable
----------
Install aglio via NPM. You need Node.js installed and you may need to use `sudo` to install globally:

```bash
npm install -g aglio
```

Then, start generating HTML. Note that the built-in templates use scheme-relative URLs, so the resulting output files must be opened via `http:` or `https:`. Just opening the local file from the browser will result in a failure to load stylesheets and scripts. The `-s` option described below can help you with this.

```bash
# Default template
aglio -i input.md -o output.html

# Get a list of built-in templates
aglio -l

# Built-in template
aglio -t slate -i input.md -o output.html

# Custom template
aglio -t /path/to/template.jade -i input.md -o output.html

# Run a live preview server on http://localhost:3000/
aglio -i input.md -s

# Print output to terminal (useful for piping)
aglio -i input.md -o -

# Disable condensing navigation links
aglio -i input.md --no-condense -o output.html

# Render full-width page instead of fixed max width
aglio -i input.md --full-width -o output.html
```

Node.js Library
---------------
You can also use aglio as a library. First, install and save it as a dependency:

```bash
npm install --save aglio
```

Then, convert some API Blueprint to HTML:

```javascript
var aglio = require('aglio');

// Render a blueprint with a template by name
var blueprint = '# Some API Blueprint string';
var template = 'default';

aglio.render(blueprint, template, function (err, html, warnings) {
    if (err) return console.log(err);
    if (warnings) console.log(warnings);

    console.log(html);
});

// Render a blueprint with a custom template file
var customTemplate = '/path/to/my-template.jade';
aglio.render(blueprint, customTemplate, function (err, html, warnings) {
    if (err) return console.log(err);
    if (warnings) console.log(warnings);

    console.log(html);
});


// Pass custom locals along to the template, for example
// the following gives templates access to lodash and async
var options = {
    template: '/path/to/my-template.jade',
    locals: {
        _: require('lodash'),
        async: require('async')
    }
};
aglio.render(blueprint, options, function (err, html, warnings) {
   if (err) return console.log(err);
   if (warnings) console.log(warnings);

   console.log(html);
});
```

### Reference
The following methods are available from the `aglio` library:

#### aglio.getTemplates (callback)
Get a list of internal template names that can be used when rendering.

```javascript
aglio.getTemplates(function (err, names) {
    if (err) return console.log(err);

    console.log('Templates: ' + names.join(', '));
});
```

#### aglio.render (blueprint, options, callback)
Render an API Blueprint string and pass the generated HTML to the callback. The `options` can either be an object of options or a simple template name or file path string. Available options are:

| Option      | Type   | Default | Description                                  |
| ----------- | ------ | ------- | -------------------------------------------- |
| condenseNav | bool   | `true`  | Condense navigation links                    |
| filterInput | bool   | `true`  | Filter `\r` and `\t` from the input          |
| locals      | object | `{}`    | Extra locals to pass to templates            |
| template    | string |         |Template name or path to custom template file |

```javascript
var blueprint = '...';
var options = {
    template: 'default',
    locals: {
        myVariable: 125
    }
};

alio.render(blueprint, options, function (err, html, warnings) {
    if (err) return console.log(err);

    console.log(html);
});
```

#### aglio.renderFile (inputFile, outputFile, options, callback)
Render an API Blueprint file and save the HTML to another file. The input/output file arguments are file paths. The options behaves the same as above for `aglio.render`.

```javascript
aglio.renderFile('/tmp/input.md', '/tmp/output.html', 'default', function (err, warnings) {
    if (err) return console.log(err);
    if (warnings) console.log(warnings);
})
```

Development
===========
Pull requests are encouraged! Feel free to fork and hack away, especially on new themes. The build system in use is Grunt, so make sure you have it installed:

```bash
npm install -g grunt-cli
```

Then you can build the source and run the tests:

```bash
# Lint/compile the Coffeescript
grunt

# Run the test suite
grunt test

# Generate an HTML test coverage report
grunt coverage

# Render examples
grunt examples
```

Custom Themes
-------------
Themes are written using Jade, with support for Coffeescript and Stylus via filters. The output of aglio is a single HTML file, but custom themes can make use of Jade's extend and include directives, which allow you to split a theme among multiple files (the built-in themes do this). The locals available to themes look like the following:

| Name        | Description                                              |
| ----------- | -------------------------------------------------------- |
| api         | The API AST from Protagonist                             |
| condenseNav | If true, you should condense the nav if possible         |
| date        | Date and time handling from Moment.js                    |
| fullWidth   | If true, you should consume the entire page width        |
| highlight   | A function (`code`, `lang`) to highlight a piece of code |
| markdown    | A function to convert Markdown strings to HTML           |
| slug        | A function to convert a string to a slug usable as an ID |
| hash        | A function to return an hash (currently MD5)             |

The default themes in the `templates` directory provide a fairly complete example of how to use the above locals. Remember, you can use any functionality available in Jade, Javascript, Coffeescript, CSS, and Stylus. Even though only one HTML page is generated, you can for example do client-side routing with Backbone, Sammy or Davis and get multiple pages on the client.

License
=======
Copyright (c) 2014 Daniel G. Taylor

http://dgt.mit-license.org/
