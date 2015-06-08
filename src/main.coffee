crypto = require 'crypto'
fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
moment = require 'moment'
path = require 'path'
protagonist = require 'protagonist'
Remarkable = require 'remarkable'

INCLUDE = /( *)<!-- include\((.*)\) -->/gmi
ROOT = path.dirname __dirname

# A function to create ID-safe slugs
slug = (value) ->
    value.toLowerCase().replace /[ \t\n]/g, '-'

# A function to highlight snippets of code. lang is optional and
# if given, is used to set the code language. If lang is no-highlight
# then no highlighting is performed.
highlight = (code, lang) ->
    if lang
        if lang is 'no-highlight'
            code
        else
            hljs.highlight(lang, code).value
    else
        hljs.highlightAuto(code).value

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

# Setup marked with code highlighting and smartypants
md = new Remarkable 'full',
    html: true
    linkify: true
    typographer: true
    highlight: highlight

# Get a list of available internal templates
exports.getTemplates = (done) ->
    fs.readdir path.join(ROOT, 'templates'), (err, files) ->
        if err then return done(err)

        # Return template names without the extension, and exclude items
        # that start with an underscore, which allows component reuse
        # among built-in templates.
        done null, (f for f in files when f[0] isnt '_').map (item) -> item.replace /\.jade$/, ''

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

parseOptions = (input, options) ->
    # Support a template name as the options argument
    if typeof options is 'string' or options instanceof String
        options =
            template: options

    # Defaults
    options.template ?= 'default'
    options.filterInput ?= true
    options.condenseNav ?= true
    options.fullWidth ?= false
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

    { input: filteredInput, options: options }

assembleLocals = (ast, options) ->
    locals =
        api: ast
        condenseNav: options.condenseNav
        fullWidth: options.fullWidth
        date: moment
        highlight: highlight
        markdown: (content) -> md.render content
        slug: slug
        hash: (value) ->
            crypto.createHash('md5').update(value.toString()).digest('hex')

    for key, value of options.locals or {}
        locals[key] = value

    locals

exports.renderSync = (input, options) ->
    { input, options } = parseOptions input, options

    try
        res = protagonist.parseSync input
    catch err
        err.input = input
        throw err

    locals = assembleLocals res.ast, options

    if fs.existsSync options.template
        templatePath = options.template
    else
        templatePath = path.join ROOT, 'templates', "#{options.template}.jade"

    jade.renderFile templatePath, locals

# Render an API Blueprint string using a given template
exports.render = (input, options, done) ->
    { input, options } = parseOptions input, options

    protagonist.parse input, (err, res) ->
        if err
            err.input = input
            return done(err)

        locals = assembleLocals res.ast, options

        fs.exists options.template, (exists) ->
            if exists
                templatePath = options.template
            else
                templatePath = path.join ROOT, 'templates', "#{options.template}.jade"

            jade.renderFile templatePath, locals, (err, html) ->
                if err then return done(err)

                # Add filtered input to warnings since we have no
                # error to return
                res.warnings.input = input

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
            if err then return done(err)
            compile input.toString()
    else
        process.stdin.setEncoding 'utf-8'
        process.stdin.on 'readable', ->
            chunk = process.stdin.read()
            if chunk?
                compile chunk
