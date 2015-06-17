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

cache = {}

# Utility for benchmarking
benchmark =
  start: (message) -> if process.env.BENCHMARK then console.time message
  end: (message) -> if process.env.BENCHMARK then console.timeEnd message

# A function to create ID-safe slugs
slug = (value='') -> value.toLowerCase().replace /[ \t\n\\:/]/g, '-'

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

getCached = (key, compiledPath, sources, load, done) ->
  # Already loaded? Just return it!
  if cache[key] then return done null, cache[key]

  # Next, try to check if the compiled path exists and is newer than all of
  # the sources. If so, load the compiled path into the in-memory cache.
  try
    if fs.existsSync compiledPath
      compiledStats = fs.statSync compiledPath

      for source in sources
        sourceStats = fs.statSync source
        if sourceStats.mtime > compiledStats.mtime
          # There is a newer source file, so we ignore the compiled
          # version on disk. It'll be regenerated later.
          return done null

      load compiledPath, (err, item) ->
        if err then return done err

        cache[key] = item
        done null, cache[key]
    else
      done null
  catch err
    done err

getCss = (variables, style, done) ->
  # Get the CSS for the given variables and style. This method caches
  # its output, so subsequent calls will be extremely fast but will
  # not reload potentially changed data from disk.
  # The CSS is generated via a dummy LESS file with imports to the
  # default variables, any custom override variables, and the given
  # layout style. Both variables and style support special values,
  # for example `flatly` might load `styles/variables-flatly.less`.
  # See the `styles` directory for available options.
  key = "css-#{variables}-#{style}"
  if cache[key] then return done null, cache[key]

  # Not cached in memory, but maybe it's already compiled on disk?
  compiledPath = path.join ROOT, 'cache', "#{slug variables}-#{slug style}.css"

  defaultColorPath = path.join ROOT, 'styles', 'variables-default.less'
  sources = [defaultColorPath]

  customColorPath = null
  if variables isnt 'default'
    customColorPath = path.join ROOT, 'styles', "variables-#{variables}.less"
    if not fs.existsSync customColorPath
      customColorPath = variables
      if not fs.existsSync customColorPath
        return done new Error "#{customColorPath} does not exist!"
    sources.push customColorPath

  stylePath = path.join ROOT, 'styles', "layout-#{style}.less"
  if not fs.existsSync stylePath
    stylePath = style
    if not fs.existsSync stylePath
      return done new Error "#{stylePath} does not exist!"

  sources.push stylePath

  load = (filename, loadDone) ->
    fs.readFile filename, 'utf-8', loadDone

  getCached key, compiledPath, sources, load, (err, css) ->
    if err then return done err
    if css then return done null, css

    # Not cached, so let's create the file.
    tmp = "@import \"#{defaultColorPath}\";\n"
    if customColorPath
      tmp += "@import \"#{customColorPath}\";\n"
    tmp += "@import \"#{stylePath}\";\n"

    benchmark.start 'less-compile'
    less.render tmp, compress: true, (err, result) ->
      if err then return done err

      try
        css = result.css
        fs.writeFileSync compiledPath, css, 'utf-8'
      catch writeErr
        return done writeErr

      benchmark.end 'less-compile'

      cache[key] = css
      done null, cache[key]

getTemplate = (name, done) ->
  # Get the template function for the given path. This will load and
  # compile the template if necessary, and cache it for future use.
  key = "template-#{name}"

  # Check if it is cached in memory. If not, then we'll check the disk.
  if cache[key] then return done null, cache[key]

  # Check if it is compiled on disk and not older than the template file.
  # If not present or outdated, then we'll need to compile it.
  compiledPath = path.join ROOT, 'cache', "#{slug name}.js"

  load = (filename, loadDone) ->
    loadDone null, require(filename)

  getCached key, compiledPath, [name], load, (err, template) ->
    if err then return done err
    if template then return done null, template

    # We need to compile the template, then cache it. This is interesting
    # because we are compiling to a client-side template, then adding some
    # module-specific code to make it work here. This allows us to save time
    # in the future by just loading the generated javascript function.
    benchmark.start 'jade-compile'
    compileOptions =
      filename: name
      name: 'compiledFunc'
      self: true
      compileDebug: false

    try
      compiled = """
        var jade = require('jade/runtime');
        #{jade.compileFileClient name, compileOptions}
        module.exports = compiledFunc;
      """
    catch compileErr
      return done compileErr

    fs.writeFileSync compiledPath, compiled, 'utf-8'
    benchmark.end 'jade-compile'

    cache[key] = require(compiledPath)
    done null, cache[key]

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
    {name: 'variables',
    description: 'Color scheme name or path to custom variables',
    default: 'default'},
    {name: 'condense-nav', description: 'Condense navigation links',
    boolean: true, default: true},
    {name: 'full-width', description: 'Use full window width',
    boolean: true, default: false},
    {name: 'template', description: 'Template name or path to custom template',
    default: 'default'},
    {name: 'style',
    description: 'Layout style name or path to custom stylesheet'}
  ]

# Render the blueprint with the given options using Jade and LESS
exports.render = (input, options, done) ->
  if not done?
    done = options
    options = {}

  # This is purely for backward-compatibility
  options.themeCondenseNav ?= options.condenseNav
  options.themeFullWidth ?= options.fullWidth

  # Setup defaults
  options.themeVariables ?= 'default'
  options.themeStyle ?= 'default'
  options.themeTemplate ?= 'default'
  options.themeCondenseNav ?= true
  options.themeFullWidth ?= false

  # Transform built-in layout names to paths
  if options.themeTemplate is 'default'
    options.themeTemplate = path.join ROOT, 'templates', 'index.jade'

  benchmark.start 'decorate'
  decorate input
  benchmark.end 'decorate'

  benchmark.start 'css-total'
  getCss options.themeVariables, options.themeStyle, (err, css) ->
    if err then return done(err)
    benchmark.end 'css-total'

    locals =
      api: input
      condenseNav: options.themeCondenseNav
      css: css
      fullWidth: options.themeFullWidth
      date: moment
      hash: (value) ->
        crypto.createHash('md5').update(value.toString()).digest('hex')
      highlight: highlight
      markdown: (content) -> md.render content
      slug: slug

    for key, value of options.locals or {}
      locals[key] = value

    benchmark.start 'get-template'
    getTemplate options.themeTemplate, (getTemplateErr, renderer) ->
      if getTemplateErr then return done(getTemplateErr)
      benchmark.end 'get-template'

      benchmark.start 'call-template'
      try html = renderer locals
      catch err then return done err
      benchmark.end 'call-template'
      done null, html
