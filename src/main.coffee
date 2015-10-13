fs = require 'fs'
path = require 'path'
protagonist = require 'protagonist'

INCLUDE = /( *)<!-- include\((.*)\) -->/gmi
ROOT = path.dirname __dirname

# Legacy template names
LEGACY_TEMPLATES = [
  'default', 'default-collapsed', 'flatly', 'flatly-collapsed', 'slate',
  'slate-collapsed', 'cyborg', 'cyborg-collapsed']

# Utility for benchmarking
benchmark =
  start: (message) -> if process.env.BENCHMARK then console.time message
  end: (message) -> if process.env.BENCHMARK then console.timeEnd message

# Extend an error's message. Returns the modified error.
errMsg = (message, err) ->
    err.message = "#{message}: #{err.message}"
    return err

# Replace the include directive with the contents of the included
# file in the input.
includeReplace = (includePath, match, spaces, filename) ->
    fullPath = path.join includePath, filename
    lines = fs.readFileSync(fullPath, 'utf-8').replace(/\r\n?/g, '\n').split('\n')
    content = spaces + lines.join "\n#{spaces}"

    # The content can itself include other files, so check those
    # as well! Beware of circular includes!
    includeDirective path.dirname(fullPath), content

# Handle the include directive, which inserts the contents of one
# file into another. We find the directive using a regular expression
# and replace it using the method above.
includeDirective = (includePath, input) ->
    input.replace INCLUDE, includeReplace.bind(this, includePath)

# Get a list of all paths from included files. This *excludes* the
# input path itself.
exports.collectPathsSync = (input, includePath) ->
    paths = []
    input.replace INCLUDE, (match, spaces, filename) ->
        fullPath = path.join(includePath, filename)
        paths.push fullPath

        content = fs.readFileSync fullPath, 'utf-8'
        paths = paths.concat exports.collectPathsSync(content, path.dirname(fullPath))
    paths

# Get the theme module for a given theme name
exports.getTheme = (name) ->
    name = 'olio' if not name or name in LEGACY_TEMPLATES
    require "aglio-theme-#{name}"

# Render an API Blueprint string using a given template
exports.render = (input, options, done) ->
    # Support a template name as the options argument
    if typeof options is 'string' or options instanceof String
        options =
            theme: options

    # Defaults
    options.filterInput ?= true
    options.includePath ?= process.cwd()
    options.theme ?= 'default'

    # For backward compatibility
    if options.template then options.theme = options.template

    if fs.existsSync options.theme
        console.log "Setting theme to olio and layout to #{options.theme}"
        options.themeLayout = options.theme
        options.theme = 'olio'
    else if options.theme isnt 'default' and options.theme in LEGACY_TEMPLATES
        variables = options.theme.split('-')[0]
        console.log "Setting theme to olio and variables to #{variables}"
        options.themeVariables = variables
        options.theme = 'olio'

    # Handle custom directive(s)
    input = includeDirective options.includePath, input

    # Protagonist does not support \r ot \t in the input, so
    # try to intelligently massage the input so that it works.
    # This is required to process files created on Windows.
    filteredInput = if not options.filterInput then input else
        input
            .replace(/\r\n?/g, '\n')
            .replace(/\t/g, '    ')

    benchmark.start 'parse'
    protagonist.parse filteredInput, type: 'ast', (err, res) ->
        benchmark.end 'parse'
        if err
            err.input = input
            return done(errMsg 'Error parsing input', err)

        try
            theme = exports.getTheme options.theme
        catch err
            return done(errMsg 'Error getting theme', err)

        # Setup default options if needed
        for option in theme.getConfig().options or []
            # Convert `foo-bar` into `themeFooBar`
            words = (f[0].toUpperCase() + f.slice(1) for f in option.name.split('-'))
            name = "theme#{words.join('')}"
            options[name] ?= option.default

        benchmark.start 'render-total'
        theme.render res.ast, options, (err, html) ->
            benchmark.end 'render-total'
            if err then return done(err)

            # Add filtered input to warnings since we have no
            # error to return
            res.warnings.input = filteredInput

            done null, html, res.warnings

# Render from/to files
exports.renderFile = (inputFile, outputFile, options, done) ->
    render = (input) ->
        exports.render input, options, (err, html, warnings) ->
            if err then return done(err)

            if outputFile isnt '-'
                fs.writeFile outputFile, html, (err) ->
                    done err, warnings
            else
                console.log html
                done null, warnings

    if inputFile isnt '-'
        options.includePath ?= path.dirname inputFile
        fs.readFile inputFile, encoding: 'utf-8', (err, input) ->
            if err then return done(errMsg 'Error reading input', err)
            render input.toString()
    else
        process.stdin.setEncoding 'utf-8'
        process.stdin.on 'readable', ->
            chunk = process.stdin.read()
            if chunk?
                render chunk

# Compile markdown from/to files
exports.compileFile = (inputFile, outputFile, done) ->
    compile = (input) ->
        compiled = includeDirective path.dirname(inputFile), input

        if outputFile isnt '-'
            fs.writeFile outputFile, compiled, (err) ->
                done err
        else
            console.log compiled
            done null

    if inputFile isnt '-'
        fs.readFile inputFile, encoding: 'utf-8', (err, input) ->
            if err then return done(errMsg 'Error writing output', err)
            compile input.toString()
    else
        process.stdin.setEncoding 'utf-8'
        process.stdin.on 'readable', ->
            chunk = process.stdin.read()
            if chunk?
                compile chunk
