#!/usr/bin/env node

var theme;
var fs = require('fs');

try {
  theme = require('../lib/main');
} catch (err) {
  require('coffee-script/register');
  theme = require('../src/main');
}

if (!fs.existsSync('./cache')) {
  fs.mkdirSync('./cache');
}

// Call with known options to generate the cache entries. This isn't that
// efficient but it works for now.
theme.render({}, function () {});
theme.render({}, {themeVariables: 'flatly'}, function () {});
