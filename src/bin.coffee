aglio = require './main'
chokidar = require 'chokidar'
clc = require 'cli-color'
fs = require 'fs'
http = require 'http'
path = require 'path'
PrettyError = require 'pretty-error'
serveStatic = require 'serve-static'
parser = require('yargs')
    .usage('Usage: $0 [options] -i infile [-o outfile -s]')
    .example('$0 -i example.apib -o output.html', 'Render to HTML')
    .example('$0 -i example.apib -s', 'Start preview server')
    .example('$0 --theme-variables flatly -i example.apib -s', 'Theme colors')
    .example('$0 --no-theme-condense-nav -i example.apib -s', 'Disable options')
    .options('i', alias: 'input', describe: 'Input file')
    .options('o', alias: 'output', describe: 'Output file')
    .options('t', alias: 'theme', describe: 'Theme name or layout file', default: 'default')
    .options('f', alias: 'filter', boolean: true, describe: 'Sanitize input from Windows', default: true)
    .options('s', alias: 'server', describe: 'Start a local live preview server')
    .options('h', alias: 'host', describe: 'Address to bind local preview server to', default: '127.0.0.1')
    .options('p', alias: 'port', describe: 'Port for local preview server', default: 3000)
    .options('v', alias: 'version', describe: 'Display version number', default: false)
    .options('c', alias: 'compile', describe: 'Compile the blueprint file', default: false)
    .options('n', alias: 'include-path', describe: 'Base directory for relative includes')
    .options('q', alias: 'quiet', boolean: true, describe: 'Suppress warning messages', default: false)
    .options('verbose', describe: 'Show verbose information and stack traces', default: false)
    .epilog('See https://github.com/danielgtaylor/aglio#readme for more information')

# Console color settings for error/warnings
cErr = clc.white.bgRed
cWarn = clc.xterm(214).bgXterm(235)

# Get the context from an error if possible
getErrContext = (input, lineNo) ->
    inputLines = input.split('\n')
    context = inputLines.slice(lineNo - 5, lineNo + 5)
    context.map (line, index) ->
        if index == 4
            cWarn(">>>>   #{line}")
        else
            "       #{line}"

# Get a line number from an error if possible
getLineNo = (input, err) ->
    if err.location and err.location.length
        input.substr(0, err.location[0].index).split('\n').length

# Output warning info
logWarnings = (warnings) ->
    if !parser.argv.quiet
        for warning in warnings or []
            lineNo = getLineNo(warnings.input, warning) or 0
            errContext = getErrContext(warnings.input, lineNo)
            console.error cWarn(">> Line #{lineNo}:") + " #{warning.message} (warning code #{warning.code})"
            console.error cWarn(">> Context")
            console.error "       ...\n #{errContext.join('\n')} \n       ..."

# Output an error message
logError = (err, verbose) ->
    if verbose
        pe = new PrettyError()
        pe.setMaxItems 5
        console.error pe.render(err)
    else
        console.error cErr('>>'), err

exports.run = (argv=parser.argv, done=->) ->
    _html = null
    getHtml = (cb) ->
        if _html
            cb and cb(null, _html)
        else
            fs.readFile argv.i, "utf-8", (err, blueprint) ->
                console.log "Rendering " + argv.i
                aglio.render blueprint, argv, (err, html, warnings) ->
                    logWarnings warnings
                    if err
                        logError err, argv.verbose
                        cb and cb(err)
                    else
                        _html = html
                        cb and cb(null, _html)

    if argv.version
        console.log("aglio #{require('../package.json').version}")
        console.log("olio #{require('aglio-theme-olio/package.json').version}")
        return done()

    # The option used to be called `template`
    if argv.template then argv.theme = argv.template

    # Backward-compatible support for -t /path/to/layout.jade
    if fs.existsSync(argv.theme)
        argv.themeTemplate = argv.theme
        argv.theme = 'default'

    # Add theme options to the help output
    if argv.verbose then console.log "Loading theme #{argv.theme}"
    try
        theme = aglio.getTheme(argv.theme)
    catch err
        err.message = "Could not load theme: #{err.message}"
        logError err, argv.verbose
        return done(err)

    config = theme.getConfig()
    for entry in config.options
        parser.options("theme-#{entry.name}", entry)

    if argv.s
        if not argv.i
            parser.showHelp()
            return done 'Invalid arguments'

        argv.locals =
            livePreview: true

        # Set where to include files from before generating HTML
        if argv.i isnt '-'
            argv.includePath = path.dirname(argv.i)

        getHtml()
        server = http.createServer((req, res) ->
            if req.url isnt '/'
                serve = serveStatic(path.dirname(argv.i))
                return serve(req, res, () -> res.end())

            getHtml (err, html) ->
                res.writeHead 200,
                    "Content-Type": "text/html"

                res.end (if err then err.toString() else html)

        ).listen argv.p, argv.h, ->
            console.log "Server started on http://#{argv.h}:#{argv.p}/"

        sendHtml = (socket) ->
            getHtml (err, html) ->
                unless err
                    console.log "Refresh web page in browser"
                    re = /<body.*?>[^]*<\/body>/gi
                    html = html.match(re)[0]
                    socket.emit "refresh", html

        io = require("socket.io")(server)
        io.on "connection", (socket) ->
            console.log "Socket connected"
            socket.on 'request-refresh', ->
                sendHtml socket

        paths = aglio.collectPathsSync fs.readFileSync(argv.i, 'utf-8'), path.dirname(argv.i)

        watcher = chokidar.watch [argv.i].concat(paths)
        watcher.on "change", (path) ->
            console.log "Updated " + path
            _html = null
            sendHtml io

        done()
    else
        # Render or Compile API Blueprint, requires input/output files
        if not argv.i or not argv.o
            parser.showHelp()
            return done 'Invalid arguments'

        if argv.c or (typeof argv.o is 'string' and (argv.o.match /\.apib$/ or argv.o.match /\.md$/))
            aglio.compileFile argv.i, argv.o, (err) ->
                if (err)
                    logError err, argv.verbose

                done()
        else
            aglio.renderFile argv.i, argv.o, argv, (err, warnings) ->
                if err
                    lineNo = getLineNo err.input, err
                    if lineNo?
                        console.error cErr(">> Line #{lineNo}:") + " #{err.message} (error code #{err.code})"
                    else
                        logError err, argv.verbose

                    return done err

                logWarnings warnings

                done()
