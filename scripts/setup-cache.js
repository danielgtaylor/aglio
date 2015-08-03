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

fs.chmodSync('./cache', 0777);

// Call with known options to generate the cache entries. This isn't that
// efficient but it works for now.
theme.render({}, function () {});
theme.render({}, {themeVariables: 'flatly'}, function () {});
theme.render({}, {themeVariables: 'slate'}, function () {});
theme.render({}, {themeVariables: 'cyborg'}, function () {});
