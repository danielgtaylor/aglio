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

getCss = (colors, style, done) ->
  # Get the CSS for the given colors and style. This method caches
  # its output, so subsequent calls will be extremely fast but will
  # not reload potentially changed data from disk.
  # The CSS is generated via a dummy LESS file with imports to the
  # default colors, any custom override colors, and the given
  # layout style. Both colors and style support special values,
  # for example `flatly` might load `styles/colors-flatly.less`.
  # See the `styles` directory for available options.
  key = "css-#{colors}-#{style}"
  if cache[key] then return done null, cache[key]

  defaultColorPath = path.join ROOT, 'styles', 'colors-default.less'

  tmp = "@import \"#{defaultColorPath}\";\n"

  if colors isnt 'default'
    customColorPath = path.join ROOT, 'styles', "colors-#{colors}.less"
    if not fs.existsSync customColorPath
      customColorPath = colors
      if not fs.existsSync customColorPath
        return done new Error "#{customColorPath} does not exist!"
    tmp += "@import \"#{customColorPath}\";\n"

  stylePath = path.join ROOT, 'styles', "layout-#{style}.less"
  if not fs.existsSync stylePath
    stylePath = style
    if not fs.existsSync stylePath
      return done new Error "#{stylePath} does not exist!"
  tmp += "@import \"#{stylePath}\";\n"

  benchmark.start 'less-compile'
  less.render tmp, compress: true, (err, css) ->
    benchmark.end 'less-compile'
    unless err then cache[key] = css
    done err, css
  return

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
  options.style ?= 'default'
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
    done null, html
