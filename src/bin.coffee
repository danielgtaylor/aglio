aglio = require './main'
fs = require 'fs'
http = require 'http'
parser = require('optimist')
    .usage('Usage: $0 [-l -t template] -i infile [-o outfile -s]')
    .options('i', alias: 'input', describe: 'Input file')
    .options('o', alias: 'output', describe: 'Output file')
    .options('t', alias: 'template', describe: 'Template name or file', default: 'default')
    .options('s', alias: 'server', describe: 'Start a local preview server')
    .options('p', alias: 'port', describe: 'Port for local preview server', default: 3000)
    .options('l', alias: 'list', describe: 'List templates')

exports.run = (argv=parser.argv, done=->) ->
    if argv.l
        # List available templates
        aglio.getTemplates (err, names) ->
            if err
                console.log err
                return done err

            console.log 'Templates:\n' + names.join('\n')

            done()
    else if argv.s
        if not argv.i
            parser.showHelp()
            return done 'Invalid arguments'

        http.createServer((req, res) ->
            if req.url isnt '/' then return res.end()

            console.log "Rendering #{argv.i}"

            blueprint = fs.readFileSync argv.i, 'utf-8'
            aglio.render blueprint, argv.t, (err, html) ->
                res.writeHead 200,
                    'Content-Type': 'text/html'
                res.end err or html
        ).listen argv.p, '127.0.0.1'
        console.log "Server started on http://localhost:#{argv.p}/"
        done()
    else
        # Render API Blueprint, requires input/output files
        if not argv.i or not argv.o
            parser.showHelp()
            return done 'Invalid arguments'

        aglio.renderFile argv.i, argv.o, argv.t, (err) ->
            if err
                console.log err
                return done err

            done()
