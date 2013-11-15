aglio = require './main'
parser = require('optimist')
    .usage('Usage: $0 [-l -t template] -i infile -o outfile')
    .describe('i', 'Input file')
    .describe('o', 'Output file')
    .describe('t', 'Template name or file')
    .describe('l', 'List templates')
    .default('t', 'default')

exports.run = (argv=parser.argv, done=->) ->
    if argv.l
        # List available templates
        aglio.getTemplates (err, names) ->
            if err
                console.log err
                return done err

            console.log 'Templates:\n' + names.join('\n')

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
