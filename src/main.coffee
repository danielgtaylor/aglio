crypto = require 'crypto'
fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
less = require 'less'
markdownIt = require 'markdown-it'
moment = require 'moment'
path = require 'path'

# The root directory of this project
ROOT = path.dirname __dirname
CSS =
  'default-default':
    fs.readFileSync path.join(ROOT, 'build', 'default-default.css'), 'utf8'
  'default-flatly':
    fs.readFileSync path.join(ROOT, 'build', 'default-flatly.css'), 'utf8'

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
md = markdownIt 'default',
  html: true
  linkify: true
  typographer: true
  highlight: highlight

# Auto-link headers
md.renderer.rules.heading_open = (tokens, idx) ->
  id = ''
  if tokens[idx + 1].type is 'inline'
    id = " id=\"header-#{slug tokens[idx + 1].content}\""

  "<h#{tokens[idx].hLevel}#{id}>"

md.renderer.rules.heading_close = (tokens, idx) ->
  link = ''
  if tokens[idx - 1].type is 'inline'
    name = slug "#{tokens[idx - 1].content}"
    link = "<a class=\"permalink\" href=\"#header-#{name}\">"
    link += '<i class="fa fa-link"></i></a>'

  "#{link}</h#{tokens[idx].hLevel}>\n"

getCss = (colors, style) ->
  key = "#{colors}-#{style}"
  if CSS.hasOwnProperty(key) then return CSS[key]

  throw new Error "Colors #{colors} style #{style} combination not available"

decorate = (api) ->
  # Decorate an API Blueprint AST with various pieces of information that
  # will be useful for the theme. Anything that would significantly
  # complicate the Jade template should probably live here instead!
  for resourceGroup in api.resourceGroups or []
    # Element ID and link
    resourceGroup.elementId = slug resourceGroup.name
    resourceGroup.elementLink = "##{resourceGroup.elementId}"

    for resource in resourceGroup.resources or []
      # Element ID and link
      resource.elementId = slug "#{resourceGroup.name}-#{resource.name}"
      resource.elementLink = "##{resource.elementId}"

      for action in resource.actions or []
        # Element ID and link
        action.elementId = slug(
          "#{resourceGroup.name}-#{resource.name}-#{action.method}")
        action.elementLink = "##{action.elementId}"

        # Lowercase HTTP method name
        action.methodLower = action.method.toLowerCase()

        # Parameters may be defined on the action or on the
        # parent resource.
        if not action.parameters or not action.parameters.length
          action.parameters = resource.parameters

        # Examples have a content section only if they have a
        # description, headers, body, or schema.
        for example in action.examples or []
          for name in ['requests', 'responses']
            for item in example[name] or []
              item.hasContent = item.description or \
                                Object.keys(item.headers).length or \
                                item.body or \
                                item.schema

              # If possible, make the body/schema pretty
              try
                if item.body
                  item.body = JSON.stringify(JSON.parse(item.body), null, 2)
                if item.schema
                  item.schema = JSON.stringify(JSON.parse(item.schema), null, 2)
              catch err
                false

# Get the theme's configuration, used by Aglio to present available
# options and confirm that the input blueprint is a supported
# version.
exports.getConfig = ->
  formats: ['1A']
  options: [
    {name: 'colors', description: 'Color scheme name or path to custom style',
    default: 'default'},
    {name: 'condense-nav', description: 'Condense navigation links',
    boolean: true, default: true},
    {name: 'full-width', description: 'Use full window width',
    boolean: true, default: false},
    {name: 'layout', description: 'Layout name or path to custom layout',
    default: 'default'},
    {name: 'style', description: 'Custom style overrides'}
  ]

# Render the blueprint with the given options using Jade and LESS
exports.render = (input, options = {}) ->

  # This is purely for backward-compatibility
  options.themeCondenseNav ?= options.condenseNav
  options.themeFullWidth ?= options.fullWidth

  # Setup defaults
  options.themeColors ?= 'default'
  options.themeStyle ?= 'default'
  options.themeLayout ?= 'default'
  options.themeCondenseNav ?= true
  options.themeFullWidth ?= false

  # Transform built-in layout names to paths
  if options.themeLayout is 'default'
    options.themeLayout = path.join ROOT, 'templates', 'index.jade'

  benchmark.start 'decorate'
  decorate input
  benchmark.end 'decorate'

  locals =
    api: input
    condenseNav: options.themeCondenseNav
    css: getCss options.themeColors, options.themeStyle
    fullWidth: options.themeFullWidth
    date: moment
    hash: (value) ->
      crypto.createHash('md5').update(value.toString()).digest('hex')
    highlight: highlight
    markdown: (content) -> md.render content
    slug: slug

  for key, value of options.locals or {}
    locals[key] = value

  compileOptions =
    filename: options.themeLayout
    self: true
    compileDebug: false

  if cache[options.themeLayout]
    renderer = cache[options.themeLayout]
  else
    benchmark.start 'jade-compile'
    fn = jade.compileFile options.themeLayout, compileOptions
    benchmark.end 'jade-compile'
    renderer = cache[options.themeLayout] = fn

  benchmark.start 'call-template'
  html = renderer locals
  benchmark.end 'call-template'

  return html
