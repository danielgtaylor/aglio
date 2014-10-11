crypto = require 'crypto'
fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
marked = require 'marked'
moment = require 'moment'
path = require 'path'
protagonist = require 'protagonist'
_ = require("lodash")

resolveActionUris = (resourceGroups) ->
    parameterReducer = (res, p) ->
        res.push p.name
        res
    _.forEach resourceGroups, (rg) ->
        _.forEach rg.resources, (r) ->
            templateUri = r.uriTemplate
            _.forEach r.actions, (a) ->
                parameterValidator = (b) ->
                    parameters.indexOf(b) is - 1
                parameters = _.reduce(a.parameters, parameterReducer, [])
                parameterBlocks = []
                lastIndex = 0
                index = 0
                while (index = templateUri.indexOf("{", index)) isnt - 1
                    parameterBlocks.push templateUri.substring(lastIndex, index)
                    block = {}
                    closeIndex = templateUri.indexOf("}", index)
                    block.querySet = templateUri.indexOf("{?", index) is index
                    lastIndex = closeIndex + 1
                    index++
                    index++ if block.querySet
                    parameterSet = templateUri.substring(index, closeIndex)
                    block.parameters = parameterSet.split(",")
                    _.remove block.parameters, parameterValidator
                    parameterBlocks.push block if block.parameters.length
                parameterBlocks.push templateUri.substring(lastIndex, templateUri.length)
                u = _.reduce(parameterBlocks, (uri, v) ->
                    if typeof v is "string"
                        uri.push v
                    else
                        segment = ["{"]
                        segment.push "?" if v.querySet
                        segment.push v.parameters.join()
                        segment.push "}"
                        uri.push segment.join("")
                    uri
                , [])
                a.uriTemplate = u.join("")
                return

            return

        return

    return

root = path.dirname __dirname

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

# Setup marked with code highlighting and smartypants
marked.setOptions
    highlight: highlight
    smartypants: true

# Get a list of available internal templates
exports.getTemplates = (done) ->
    fs.readdir path.join(root, 'templates'), (err, files) ->
        if err then return done(err)

        # Return template names without the extension, and exclude items
        # that start with an underscore, which allows component reuse
        # among built-in templates.
        done null, (f for f in files when f[0] isnt '_').map (item) -> item.replace /\.jade$/, ''

# Render an API Blueprint string using a given template
exports.render = (input, options, done) ->
    # Support a template name as the options argument
    if typeof options is 'string' or options instanceof String
        options =
            template: options

    # Defaults
    options.template ?= 'default'
    options.filterInput ?= true
    options.condenseNav ?= true
    options.fullWidth ?= false

    # Protagonist does not support \r ot \t in the input, so
    # try to intelligently massage the input so that it works.
    # This is required to process files created on Windows.
    filteredInput = if not options.filterInput then input else
        input
            .replace(/\r\n?/g, '\n')
            .replace(/\t/g, '    ')

    protagonist.parse filteredInput, (err, res) ->
        if err
            err.input = filteredInput
            return done(err)

        resolveActionUris res.ast.resourceGroups

        locals =
            api: res.ast
            condenseNav: options.condenseNav
            fullWidth: options.fullWidth
            date: moment
            highlight: highlight
            markdown: marked
            slug: slug
            hash: (value) ->
                crypto.createHash('md5').update(value.toString()).digest('hex')

        for key, value of options.locals or {}
            locals[key] = value

        if fs.existsSync options.template
            templatePath = options.template
        else
            templatePath = path.join root, 'templates', "#{options.template}.jade"

        jade.renderFile templatePath, locals, (err, html) ->
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
        fs.readFile inputFile, encoding: 'utf-8', (err, input) ->
            if err then return done(err)
            render input.toString()
    else
        process.stdin.setEncoding 'utf-8'
        process.stdin.on 'readable', ->
            chunk = process.stdin.read()
            if chunk?
                render chunk
