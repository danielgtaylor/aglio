crypto = require 'crypto'
fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
less = require 'less'
markdownIt = require 'markdown-it'
moment = require 'moment'
path = require 'path'
querystring = require 'querystring'

renderExample = require './example'
renderSchema = require './schema'

# The root directory of this project
ROOT = path.dirname __dirname

cache = {}

# Utility for benchmarking
benchmark =
  start: (message) -> if process.env.BENCHMARK then console.time message
  end: (message) -> if process.env.BENCHMARK then console.timeEnd message

# Extend an error's message. Returns the modified error.
errMsg = (message, err) ->
  err.message = "#{message}: #{err.message}"
  return err

# Generate a SHA1 hash
sha1 = (value) ->
  crypto.createHash('sha1').update(value.toString()).digest('hex')

# A function to create ID-safe slugs. If `unique` is passed, then
# unique slugs are returned for the same input. The cache is just
# a plain object where the keys are the sluggified name.
slug = (cache={}, value='', unique=false) ->
  sluggified = value.toLowerCase()
                    .replace(/[ \t\n\\<>"'=:/]/g, '-')
                    .replace(/-+/g, '-')
                    .replace(/^-/, '')

  if unique
    while cache[sluggified]
      # Already exists, so let's try to make it unique.
      if sluggified.match /\d+$/
        sluggified = sluggified.replace /\d+$/, (value) ->
          parseInt(value) + 1
      else
        sluggified = sluggified + '-1'

  cache[sluggified] = true

  return sluggified

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
  return response.trim()

getCached = (key, compiledPath, sources, load, done) ->
  # Disable the template/css caching?
  if process.env.NOCACHE then return done null

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

      try
        load compiledPath, (err, item) ->
          if err then return done(errMsg 'Error loading cached resource', err)

          cache[key] = item
          done null, cache[key]
      catch loadErr
        return done(errMsg 'Error loading cached resource', loadErr)
    else
      done null
  catch err
    done err

getCss = (variables, styles, verbose, done) ->
  # Get the CSS for the given variables and style. This method caches
  # its output, so subsequent calls will be extremely fast but will
  # not reload potentially changed data from disk.
  # The CSS is generated via a dummy LESS file with imports to the
  # default variables, any custom override variables, and the given
  # layout style. Both variables and style support special values,
  # for example `flatly` might load `styles/variables-flatly.less`.
  # See the `styles` directory for available options.
  key = "css-#{variables}-#{styles}"
  if cache[key] then return done null, cache[key]

  # Not cached in memory, but maybe it's already compiled on disk?
  compiledPath = path.join ROOT, 'cache',
    "#{sha1 key}.css"

  defaultVariablePath = path.join ROOT, 'styles', 'variables-default.less'
  sources = [defaultVariablePath]

  if not Array.isArray(variables) then variables = [variables]
  if not Array.isArray(styles) then styles = [styles]

  variablePaths = [defaultVariablePath]
  for item in variables
    if item isnt 'default'
      customPath = path.join ROOT, 'styles', "variables-#{item}.less"
      if not fs.existsSync customPath
        customPath = item
        if not fs.existsSync customPath
          return done new Error "#{customPath} does not exist!"
      variablePaths.push customPath
      sources.push customPath

  stylePaths = []
  for item in styles
    customPath = path.join ROOT, 'styles', "layout-#{item}.less"
    if not fs.existsSync customPath
      customPath = item
      if not fs.existsSync customPath
        return done new Error "#{customPath} does not exist!"
    stylePaths.push customPath
    sources.push customPath

  load = (filename, loadDone) ->
    fs.readFile filename, 'utf-8', loadDone

  if verbose
    console.log "Using variables #{variablePaths}"
    console.log "Using styles #{stylePaths}"
    console.log "Checking cache #{compiledPath}"

  getCached key, compiledPath, sources, load, (err, css) ->
    if err then return done err
    if css
      if verbose then console.log 'Cached version loaded'
      return done null, css

    # Not cached, so let's create the file.
    if verbose
      console.log 'Not cached or out of date. Generating CSS...'

    tmp = ''

    for customPath in variablePaths
      tmp += "@import \"#{customPath}\";\n"

    for customPath in stylePaths
      tmp += "@import \"#{customPath}\";\n"

    benchmark.start 'less-compile'
    less.render tmp, compress: true, (err, result) ->
      if err then return done(msgErr 'Error processing LESS -> CSS', err)

      try
        css = result.css
        fs.writeFileSync compiledPath, css, 'utf-8'
      catch writeErr
        return done(errMsg 'Error writing cached CSS to file', writeErr)

      benchmark.end 'less-compile'

      cache[key] = css
      done null, cache[key]

compileTemplate = (filename, options) ->
  compiled = """
    var jade = require('jade/runtime');
    #{jade.compileFileClient filename, options}
    module.exports = compiledFunc;
  """

getTemplate = (name, verbose, done) ->
  # Check if this is a built-in template name
  builtin = path.join(ROOT, 'templates', "#{name}.jade")
  if not fs.existsSync(name) and fs.existsSync(builtin)
    name = builtin

  # Get the template function for the given path. This will load and
  # compile the template if necessary, and cache it for future use.
  key = "template-#{name}"

  # Check if it is cached in memory. If not, then we'll check the disk.
  if cache[key] then return done null, cache[key]

  # Check if it is compiled on disk and not older than the template file.
  # If not present or outdated, then we'll need to compile it.
  compiledPath = path.join ROOT, 'cache', "#{sha1 key}.js"

  load = (filename, loadDone) ->
    try
      loaded = require(filename)
    catch loadErr
      return loadDone(errMsg 'Unable to load template', loadErr)

    loadDone null, require(filename)

  if verbose
    console.log "Using template #{name}"
    console.log "Checking cache #{compiledPath}"

  getCached key, compiledPath, [name], load, (err, template) ->
    if err then return done err
    if template
      if verbose then console.log 'Cached version loaded'
      return done null, template

    if verbose
      console.log 'Not cached or out of date. Generating template JS...'

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
      compiled = compileTemplate name, compileOptions
    catch compileErr
      return done(errMsg 'Error compiling template', compileErr)

    if compiled.indexOf('self.') is -1
      # Not using self, so we probably need to recompile into compatibility
      # mode. This is slower, but keeps things working with Jade files
      # designed for Aglio 1.x.
      compileOptions.self = false

      try
        compiled = compileTemplate name, compileOptions
      catch compileErr
        return done(errMsg 'Error compiling template', compileErr)

    try
      fs.writeFileSync compiledPath, compiled, 'utf-8'
    catch writeErr
      return done(errMsg 'Error writing cached template file', writeErr)

    benchmark.end 'jade-compile'

    cache[key] = require(compiledPath)
    done null, cache[key]

modifyUriTemplate = (templateUri, parameters, colorize) ->
  # Modify a URI template to only include the parameter names from
  # the given parameters. For example:
  # URI template: /pages/{id}{?verbose}
  # Parameters contains a single `id` parameter
  # Output: /pages/{id}
  parameterValidator = (b) ->
    # Compare the names, removing the special `*` operator
    parameterNames.indexOf(
      querystring.unescape b.replace(/^\*|\*$/, '')) isnt -1
  parameterNames = (param.name for param in parameters)
  parameterBlocks = []
  lastIndex = index = 0
  while (index = templateUri.indexOf("{", index)) isnt - 1
    parameterBlocks.push templateUri.substring(lastIndex, index)
    block = {}
    closeIndex = templateUri.indexOf("}", index)
    block.querySet = templateUri.indexOf("{?", index) is index
    block.formSet = templateUri.indexOf("{&", index) is index
    block.reservedSet = templateUri.indexOf("{+", index) is index
    lastIndex = closeIndex + 1
    index++
    index++ if block.querySet or block.formSet or block.reservedSet
    parameterSet = templateUri.substring(index, closeIndex)
    block.parameters = parameterSet.split(",").filter(parameterValidator)
    parameterBlocks.push block if block.parameters.length
  parameterBlocks.push templateUri.substring(lastIndex, templateUri.length)
  parameterBlocks.reduce((uri, v) ->
    if typeof v is "string"
      uri.push v
    else
      segment = if not colorize then ["{"] else []
      segment.push "?" if v.querySet
      segment.push "&" if v.formSet
      segment.push "+" if v.reservedSet and not colorize
      segment.push v.parameters.map((name) ->
        if not colorize then name else
          # TODO: handle errors here?
          name = name.replace(/^\*|\*$/, '')
          param = parameters[parameterNames.indexOf(querystring.unescape name)]
          if v.querySet or v.formSet
            "<span class=\"hljs-attribute\">#{name}=</span>" +
              "<span class=\"hljs-literal\">#{param.example || ''}</span>"
          else
            "<span class=\"hljs-attribute\" title=\"#{name}\">#{
              param.example || name}</span>"
        ).join(if colorize then '&' else ',')
      if not colorize
        segment.push "}"
      uri.push segment.join("")
    uri
  , []).join('').replace(/\/+/g, '/')

decorate = (api, md, slugCache, verbose) ->
  # Decorate an API Blueprint AST with various pieces of information that
  # will be useful for the theme. Anything that would significantly
  # complicate the Jade template should probably live here instead!

  # Use the slug caching mechanism
  slugify = slug.bind slug, slugCache

  # Find data structures. This is a temporary workaround until Drafter is
  # updated to support JSON Schema again.
  # TODO: Remove me when Drafter is released.
  dataStructures = {}
  for category in api.content or []
    for item in category.content or []
      if item.element is 'dataStructure'
        dataStructure = item.content[0]
        dataStructures[dataStructure.meta.id] = dataStructure
  if verbose
    console.log "Known data structures: #{Object.keys(dataStructures)}"

  # API overview description
  if api.description
    api.descriptionHtml = md.render api.description
    api.navItems = slugCache._nav
    slugCache._nav = []

  for meta in api.metadata or []
    if meta.name is 'HOST'
      api.host = meta.value

  for resourceGroup in api.resourceGroups or []
    # Element ID and link
    resourceGroup.elementId = slugify resourceGroup.name, true
    resourceGroup.elementLink = "##{resourceGroup.elementId}"

    # Description
    if resourceGroup.description
      resourceGroup.descriptionHtml = md.render resourceGroup.description
      resourceGroup.navItems = slugCache._nav
      slugCache._nav = []

    for resource in resourceGroup.resources or []
      # Element ID and link
      resource.elementId = slugify(
        "#{resourceGroup.name}-#{resource.name}", true)
      resource.elementLink = "##{resource.elementId}"

      for action in resource.actions or []
        # Element ID and link
        action.elementId = slugify(
          "#{resourceGroup.name}-#{resource.name}-#{action.method}", true)
        action.elementLink = "##{action.elementId}"

        # Lowercase HTTP method name
        action.methodLower = action.method.toLowerCase()

        # Parameters may be defined on the action or on the
        # parent resource. Resource parameters should be concatenated
        # to the action-specific parameters if set.
        if not (action.attributes or {}).uriTemplate
          if not action.parameters or not action.parameters.length
            action.parameters = resource.parameters
          else if resource.parameters
            action.parameters = resource.parameters.concat(action.parameters)

        # Remove any duplicates! This gives precedence to the parameters
        # defined on the action.
        knownParams = {}
        newParams = []
        reversed = (action.parameters or []).concat([]).reverse()
        for param in reversed
          if knownParams[param.name] then continue
          knownParams[param.name] = true
          newParams.push param

        action.parameters = newParams.reverse()

        # Set up the action's template URI
        action.uriTemplate = modifyUriTemplate(
          (action.attributes or {}).uriTemplate or resource.uriTemplate or '',
          action.parameters)

        action.colorizedUriTemplate = modifyUriTemplate(
          (action.attributes or {}).uriTemplate or resource.uriTemplate or '',
          action.parameters, true)

        # Examples have a content section only if they have a
        # description, headers, body, or schema.
        action.hasRequest = false
        for example in action.examples or []
          for name in ['requests', 'responses']
            for item in example[name] or []
              if name is 'requests' and not action.hasRequest
                action.hasRequest = true

              # If there is no schema, but there are MSON attributes, then try
              # to generate the schema. This will fail sometimes.
              # TODO: Remove me when Drafter is released.
              if not item.schema and item.content
                for dataStructure in item.content
                  if dataStructure.element is 'dataStructure'
                    try
                      schema = renderSchema(
                        dataStructure.content[0], dataStructures)
                      schema['$schema'] =
                        'http://json-schema.org/draft-04/schema#'
                      item.schema = JSON.stringify(schema, null, 2)
                    catch err
                      if verbose
                        console.log(
                          JSON.stringify dataStructure.content[0], null, 2)
                        console.log(err)

              if item.content and not process.env.DRAFTER_EXAMPLES
                for dataStructure in item.content
                  if dataStructure.element is 'dataStructure'
                    try
                      item.body = JSON.stringify(renderExample(
                        dataStructure.content[0], dataStructures), null, 2)
                    catch err
                      if verbose
                        console.log(
                          JSON.stringify dataStructure.content[0], null, 2)
                        console.log(err)

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
    description: 'Layout style name or path to custom stylesheet'},
    {name: 'emoji', description: 'Enable support for emoticons',
    boolean: true, default: true}
  ]

# Render the blueprint with the given options using Jade and LESS
exports.render = (input, options, done) ->
  if not done?
    done = options
    options = {}

  # Disable the template/css caching?
  if process.env.NOCACHE then cache = {}

  # This is purely for backward-compatibility
  if options.condenseNav then options.themeCondenseNav = options.condenseNav
  if options.fullWidth then options.themeFullWidth = options.fullWidth

  # Setup defaults
  options.themeVariables ?= 'default'
  options.themeStyle ?= 'default'
  options.themeTemplate ?= 'default'
  options.themeCondenseNav ?= true
  options.themeFullWidth ?= false

  # Transform built-in layout names to paths
  if options.themeTemplate is 'default'
    options.themeTemplate = path.join ROOT, 'templates', 'index.jade'

  # Setup markdown with code highlighting and smartypants. This also enables
  # automatically inserting permalinks for headers.
  slugCache =
    _nav: []
  md = markdownIt(
    html: true
    linkify: true
    typographer: true
    highlight: highlight
  ).use(require('markdown-it-anchor'),
    slugify: (value) ->
      output = "header-#{slug(slugCache, value, true)}"
      slugCache._nav.push [value, "##{output}"]
      return output
    permalink: true
    permalinkClass: 'permalink'
  ).use(require('markdown-it-checkbox')
  ).use(require('markdown-it-container'), 'note'
  ).use(require('markdown-it-container'), 'warning')

  if options.themeEmoji then md.use require('markdown-it-emoji')

  # Enable code highlighting for unfenced code blocks
  md.renderer.rules.code_block = md.renderer.rules.fence

  benchmark.start 'decorate'
  decorate input, md, slugCache, options.verbose
  benchmark.end 'decorate'

  benchmark.start 'css-total'
  {themeVariables, themeStyle, verbose} = options
  getCss themeVariables, themeStyle, verbose, (err, css) ->
    if err then return done(errMsg 'Could not get CSS', err)
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
      slug: slug.bind(slug, slugCache)
      urldec: (value) -> querystring.unescape(value)

    for key, value of options.locals or {}
      locals[key] = value

    benchmark.start 'get-template'
    getTemplate options.themeTemplate, verbose, (getTemplateErr, renderer) ->
      if getTemplateErr
        return done(errMsg 'Could not get template', getTemplateErr)
      benchmark.end 'get-template'

      benchmark.start 'call-template'
      try html = renderer locals
      catch err
        return done(errMsg 'Error calling template during rendering', err)
      benchmark.end 'call-template'
      done null, html
