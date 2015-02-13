fs = require 'fs'
path = require 'path'
protagonist = require 'protagonist'

INCLUDE = /( *)<!-- include\((.*)\) -->/gmi
ROOT = path.dirname __dirname

# Utility for benchmarking
benchmark =
  start: (message) -> if process.env.BENCHMARK then console.time message
  end: (message) -> if process.env.BENCHMARK then console.timeEnd message

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

# Get a list of available internal legacy templates
exports.getTemplates = (done) ->
    done null, ['cyborg', 'default', 'flatly', 'slate']

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
    name = 'olio' if name in ['cyborg', 'default', 'flatly', 'slate']
    require "aglio-theme-#{name}"

# Render an API Blueprint string using a given template
exports.render = (input, options, done) ->
    # Support a template name as the options argument
    if typeof options is 'string' or options instanceof String
        options =
            template: options

    # Defaults
    options.template ?= 'default'
    options.includePath ?= process.cwd()

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
    protagonist.parse filteredInput, (err, res) ->
        if err
            err.input = filteredInput
            return done(err)
        benchmark.end 'parse'

        theme = exports.getTheme options.template
        benchmark.start 'render-total'
        theme.render res.ast, options, (err, html) ->
            if err then return done(err)
            benchmark.end 'render-total'

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
            if err then return done(err)
            render input.toString()
    else
        process.stdin.setEncoding 'utf-8'
        process.stdin.on 'readable', ->
            chunk = process.stdin.read()
            if chunk?
                render chunk
