fs = require 'fs'
hljs = require 'highlight.js'
jade = require 'jade'
marked = require 'marked'
moment = require 'moment'
path = require 'path'
protagonist = require 'protagonist'

root = path.dirname __dirname

# A function to create ID-safe slugs
slug = (value) ->
    value.toLowerCase().replace /[ \t\n]/, '-'

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
        
        done null, files.map (item) -> item.replace /\.jade$/, ''

# Render an API Blueprint string using a given template
exports.render = (input, template, done) ->
    protagonist.parse input, (err, res) ->
        if err then return done(err)

        locals =
            api: res.ast
            date: moment
            highlight: highlight
            markdown: marked
            slug: slug

        if fs.existsSync template
            templatePath = template
        else
            templatePath = path.join root, 'templates', "#{template}.jade"

        jade.renderFile templatePath, locals, (err, html) ->
            if err then return done(err)

            done null, html

# Render from/to files
exports.renderFile = (inputFile, outputFile, template, done) ->
    fs.readFile inputFile, encoding: 'utf-8', (err, input) ->
        if err then return done(err)

        exports.render input, template, (err, html) ->
            if err then return done(err)

            if outputFile isnt '-'
                fs.writeFile outputFile, html, done
            else
                console.log html
                done()
