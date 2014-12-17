aglio = require './main'
chokidar = require 'chokidar'
clc = require 'cli-color'
fs = require 'fs'
http = require 'http'
path = require 'path'
parser = require('yargs')
    .usage('Usage: $0 [options] -i infile [-o outfile -s]')
    .example('$0 -i example.md -o output.html', 'Render to HTML')
    .example('$0 -i example.md -s', 'Start preview server')
    .example('$0 -t flatly -i example.md -s', 'Custom template')
    .example('$0 --no-condense -i example.md -s', 'Disable options')
    .options('i', alias: 'input', describe: 'Input file')
    .options('o', alias: 'output', describe: 'Output file')
    .options('t', alias: 'template', describe: 'Template name or file', default: 'default')
    .options('f', alias: 'filter', boolean: true, describe: 'Sanitize input from Windows', default: true)
    .options('c', alias: 'condense', boolean: true, describe: 'Condense navigation links', default: true)
    .options('w', alias: 'full-width', boolean: true, describe: 'Use full window width', default: false)
    .options('s', alias: 'server', describe: 'Start a local live preview server')
    .options('h', alias: 'host', describe: 'Address to bind local preview server to', default: '127.0.0.1')
    .options('p', alias: 'port', describe: 'Port for local preview server', default: 3000)
    .options('l', alias: 'list', describe: 'List templates')
    .strict()

# Console color settings for error/warnings
cErr = clc.white.bgRed
cWarn = clc.xterm(214).bgXterm(235)

# Get a line number from an error if possible
getLineNo = (input, err) ->
    if err.location and err.location.length
        input.substr(0, err.location[0].index).split('\n').length

# Output warning info
logWarnings = (warnings) ->
    for warning in warnings or []
        lineNo = getLineNo(warnings.input, warning) or 0
        console.error cWarn(">> Line #{lineNo}:") + " #{warning.message} (warning code #{warning.code})"

exports.run = (argv=parser.argv, done=->) ->
    _html = null
    getHtml = (cb) ->
        if _html
            cb and cb(null, _html)
        else
            options =
                template: argv.t
                filterInput: argv.f
                condenseNav: argv.c
                fullWidth: argv.w
                includePath: path.dirname argv.i
                locals:
                    livePreview: true

            fs.readFile argv.i, "utf-8", (err, blueprint) ->
                console.log "Rendering " + argv.i
                aglio.render blueprint, options, (err, html, warnings) ->
                    logWarnings warnings
                    if err
                        console.error err
                        cb and cb(err)
                    else
                        _html = html
                        cb and cb(null, _html)
    if argv.l
        # List available templates
        aglio.getTemplates (err, names) ->
            if err
                console.error err
                return done err

            console.log 'Templates:\n' + names.join('\n')

            done()
    else if argv.s
        if not argv.i
            parser.showHelp()
            return done 'Invalid arguments'

        getHtml()
        server = http.createServer((req, res) ->
            if req.url isnt '/' then return res.end()

            getHtml (err, html) ->
                res.writeHead 200,
                    "Content-Type": "text/html"

                res.end (if err then err.toString() else html)

        ).listen argv.p, argv.h, ->
            console.log "Server started on http://#{argv.h}:#{argv.p}/"

        io = require("socket.io")(server)
        io.on "connection", () ->
            console.log "Socket connected"

        paths = aglio.collectPathsSync fs.readFileSync(argv.i, 'utf-8'), path.dirname(argv.i)

        watcher = chokidar.watch [argv.i].concat(paths)
        watcher.on "change", (path) ->
            console.log "Updated " + path
            _html = null
            getHtml (err, html) ->
                unless err
                    console.log "Refresh web page in browser"
                    re = /<body>[\s\S]*<\/body>/i
                    html = html.match(re)[0]
                    io.emit "refresh", html

        done()
    else
        # Render API Blueprint, requires input/output files
        if not argv.i or not argv.o
            parser.showHelp()
            return done 'Invalid arguments'

        options =
            template: argv.t
            filterInput: argv.f
            condenseNav: argv.c
            fullWidth: argv.w

        aglio.renderFile argv.i, argv.o, options, (err, warnings) ->
            if err
                lineNo = getLineNo err.input, err
                if lineNo?
                    console.error cErr(">> Line #{lineNo}:") + " #{err.message} (error code #{err.code})"
                else
                    console.error cErr('>>') + " #{JSON.stringify(err)}"
                return done err

            logWarnings warnings

            done()
