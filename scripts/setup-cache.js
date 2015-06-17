#!/usr/bin/env node

var theme = require('../lib/main');
var fs = require('fs');

if (!fs.existsSync('./cache')) {
  fs.mkdirSync('./cache');
}

// Call with known options to generate the cache entries. This isn't that
// efficient but it works for now.
theme.render({}, function () {});
theme.render({}, {themeVariables: 'flatly'}, function () {});
