fs = require 'fs'
path = require 'path'
request = require 'sync-request'

INCLUDE_REGEX = /( *)<!-- include\((.*?)\)\s*(filesystem\((.*)\))?\s*-->/gmi

# Replace the include directive with the contents of the included
# file in the input.
replaceText = (options, match, spaces, filename, filesystem, type) ->
    if type == 'host'
        content = readWebContent("#{options.includeHost}#{filename}", spaces)
    else
        fullPath = path.join options.includePath, filename
        lines = fs.readFileSync(fullPath, 'utf-8').replace(/\r\n?/g, '\n').split('\n')
        content = spaces + lines.join "\n#{spaces}"
        options.includePath = path.dirname(fullPath)
        # The content can itself include other files, so check those
        # as well! Beware of circular includes!

    this.replace content, options

# Request web content
readWebContent = (path, spaces) ->
    spaces ?= '  '
    try
        response = request('GET', path)
        if response.statusCode == 200
            spaces + response.getBody()
        else
            ''
    catch error
        console.error "Invalid HTTP page #{path}"
        ''

# Handle the include directive, which inserts the contents of one
# file into another. We find the directive using a regular expression
# and replace it using the method above.
exports.replace = (input, options) ->
    input.replace INCLUDE_REGEX, replaceText.bind(this, options)

# Get a list of all paths from included files. This *excludes* the
# input path itself.
exports.collectPathsSync = (input, options) ->
    paths = []
    input.replace INCLUDE_REGEX, (match, spaces, filename, filesystem, type) ->
        if type == 'host'
            fullPath = "#{options.includeHost}#{filename}"
            paths.push fullPath
            content = readWebContent(fullPath)
            paths = paths.concat exports.collectPathsSync(content, options)

        else
            fullPath = path.join(options.includePath, filename)
            paths.push fullPath

            content = fs.readFileSync fullPath, 'utf-8'
            paths = paths.concat exports.collectPathsSync(content, path.dirname(fullPath))
    paths
