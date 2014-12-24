crypto = require 'crypto'
fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
less = require 'less'
moment = require 'moment'
path = require 'path'
Remarkable = require 'remarkable'

# The root directory of this project
ROOT = path.dirname __dirname

cache = {}

# Utility for benchmarking
benchmark =
  start: (message) -> if process.env.BENCHMARK then console.time message
  end: (message) -> if process.env.BENCHMARK then console.timeEnd message

# A function to create ID-safe slugs
slug = (value='') -> value.toLowerCase().replace /[ \t\n]/g, '-'

# A function to highlight snippets of code. lang is optional and
# if given, is used to set the code language. If lang is no-highlight
# then no highlighting is performed.
highlight = (code, lang, subset) ->
  benchmark.start "highlight #{lang}"
  response = switch lang
    when 'no-highlight' then code
    when undefined, null, ''
      hljs.highlightAuto(code, subset).value
    else hljs.highlight(lang, code).value
  benchmark.end "highlight #{lang}"
  return response

# Setup marked with code highlighting and smartypants
md = new Remarkable 'full',
  html: true
  linkify: true
  typographer: true
  highlight: highlight

getColors = (name, done) ->
  # First check to see if this is a built-in style
  fullPath = path.join ROOT, 'styles', "colors-#{name}.less"
  fs.exists fullPath, (exists) ->
    if exists then fs.readFile fullPath, 'utf-8', done else
      # This is not a built-in color set, so instead we load
      # the default color scheme and the custom colors file.
      fs.exists name, (exists) ->
        if not exists then return done new Error "File #{name} not found!"

        defaults = path.join ROOT, 'styles', 'colors-default.less'
        fs.readFile defaults, 'utf-8', (err, defaultData) ->
          if err then return done err

          fs.readFile name, 'utf-8', (err, customData) ->
            if err then return done err

            done null, "#{defaultData}\n#{customData}"

getCss = (colors, style, done) ->
  # If colors is one of ['default', 'cyborg', 'flatly', 'slate']
  # then load them as the defaults. If not, then load the
  # 'defaults' colors, load the custom colors and merge the two.
  # Next, load the default style. If there is a custom style
  # defined, then load that and append it as well. Once finished,
  # render out the CSS.
  getColors colors, (err, colorData) ->
    if err then return done(err)

    defaultStylePath = path.join ROOT, 'styles', 'layout-default.less'
    fs.readFile defaultStylePath, 'utf-8', (err, defaultData) ->
      if err then return done(err)

      fs.exists style or '', (exists) ->
        if exists
          fs.readFile style, 'utf-8', (err, customData) ->
            if err then return done err
            style = "#{colorData}\n#{defaultData}\n#{customData}"
            less.render style, done
        else
          if style
            return done new Error "File #{style} not found!"
          else
            style = "#{colorData}\n#{defaultData}"
            less.render style, compress: true, done

# Get the theme's configuration, used by Aglio to present available
# options and confirm that the input blueprint is a supported
# version.
exports.getConfig = ->
  formats: ['1A']
  options: [
    {name: 'colors', description: 'Color scheme name or path to custom style',
    default: 'default'},
    {name: 'condenseNav', description: 'Condense navigation links',
    boolean: true, default: true},
    {name: 'fullWidth', description: 'Use full window width',
    boolean: true, default: false},
    {name: 'layout', description: 'Layout name or path to custom layout',
    default: 'default'},
    {name: 'style', description: 'Custom style overrides'}
  ]

# Render the blueprint with the given options using Jade and Stylus
exports.render = (input, options, done) ->
  if not done?
    done = options
    options = {}

  options.colors ?= 'default'
  options.layout ?= path.join ROOT, 'templates', 'index.jade'

  benchmark.start 'css'
  getCss options.colors, options.style, (err, lessOutput) ->
    if err then return done(err)
    benchmark.end 'css'

    locals =
      api: input
      condenseNav: options.condenseNav
      css: lessOutput.css
      fullWidth: options.fullWidth
      date: moment
      hash: (value) ->
        crypto.createHash('md5').update(value.toString()).digest('hex')
      highlight: highlight
      markdown: (content) -> md.render content
      slug: slug

    for key, value of options.locals or {}
      locals[key] = value

    compileOptions =
      filename: options.layout
      self: true
      compileDebug: false

    if cache[options.layout]
      renderer = cache[options.layout]
    else
      benchmark.start 'compile'
      try fn = jade.compileFile options.layout, compileOptions
      catch err then return done err
      benchmark.end 'compile'
      renderer = cache[options.layout] = fn

    benchmark.start 'template'
    try html = renderer locals
    catch err then return done err
    benchmark.end 'template'
    done err, html
