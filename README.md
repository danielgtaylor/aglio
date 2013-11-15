Aglio
=====
[![Dependency Status](https://gemnasium.com/danielgtaylor/aglio.png)](https://gemnasium.com/danielgtaylor/aglio) [![Build Status](https://travis-ci.org/danielgtaylor/aglio.png)](https://travis-ci.org/danielgtaylor/aglio) [![Coverage Status](https://coveralls.io/repos/danielgtaylor/aglio/badge.png)](https://coveralls.io/r/danielgtaylor/aglio) [![NPM version](https://badge.fury.io/js/aglio.png)](http://badge.fury.io/js/aglio)

An [API Blueprint](http://apiblueprint.org/) renderer that supports multiple themes and outputs static HTML that can be served by any web host. Features:

 * Fast parsing thanks to [Protagonist](https://github.com/apiaryio/protagonist)
 * Asyncronous processing
 * Multiple templates
 * Support for custom templates written in [Jade](http://jade-lang.com/)
 * Commandline executable `aglio -i api.md -o api.html`
 * Node.js library `require('aglio')`
 * Excellent test coverage

#### Example Output

 * [Default theme](http://htmlpreview.github.io/?https://github.com/danielgtaylor/aglio/blob/master/examples/default.html)
 * [Slate theme](http://htmlpreview.github.io/?https://github.com/danielgtaylor/aglio/blob/master/examples/slate.html)

Installation & Usage
--------------------
Install aglio via NPM (you may need `sudo`):

```bash
npm install -g aglio
```

Then, start generating HTML:

```bash
# Default template
aglio -i input.md -o output.html

# Get a list of built-in templates
aglio -l

# Built-in template
aglio -t slate -i input.md -o output.html

# Custom template
aglio -t /path/to/template.jade -i input.md -o output.html

# Print output to terminal (useful for piping)
algio -i input.md -o -
```

Node.js
-------
You can also use aglio as a library. First, install and save it as a dependency:

```bash
npm install --save aglio
```

Then, convert some API Blueprint to HTML:

```javascript
var aglio = require('aglio');

var blueprint = '# Some API Blueprint string';

aglio.render(blueprint, 'default', function (err, html) {
    if (err) console.log(err);

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

#### aglio.render (blueprint, template, callback)
Render an API Blueprint string with the given template and pass the generated HTML to the callback.

```javascript
var blueprint = '...';
alio.render(blueprint, 'default', function (err, html) {
    if (err) return console.log(err);

    console.log(html);
});
```

#### aglio.renderFile (inputFile, outputFile, template, callback)
Render an API Blueprint file and save the HTML to another file. The input/output file arguments are file paths.

```javascript
aglio.renderFile('/tmp/input.md', '/tmp/output.html', 'default', function (err) {
    if (err) return console.log(err);
})
```

Development
-----------
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
```

License
-------
Copyright (c) 2013 Daniel G. Taylor

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
