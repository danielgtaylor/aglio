aglio = require '../lib/main'
assert = require 'assert'
bin = require '../lib/bin'
fs = require 'fs'
http = require 'http'
path = require 'path'
protagonist = require 'protagonist'
sinon = require 'sinon'

root = path.dirname(__dirname)

blueprint = fs.readFileSync path.join(root, 'example.apib'), 'utf-8'

describe 'API Blueprint Renderer', ->
    it 'Should load the default theme', ->
        theme = aglio.getTheme 'default'

        assert.ok theme

    it 'Should get a list of included files', ->
        sinon.stub fs, 'readFileSync', -> 'I am a test file'

        input = '''
            # Title
            <!-- include(test1.apib) -->
            Some content...
            <!-- include(test2.apib) -->
            More content...
        '''

        paths = aglio.collectPathsSync input, '.'

        fs.readFileSync.restore()

        assert.equal paths.length, 2
        assert 'test1.apib' in paths
        assert 'test2.apib' in paths

    it 'Should render blank string', (done) ->
        aglio.render '', template: 'default', locals: {foo: 1}, (err, html) ->
            if err then return done(err)

            assert html

            done()

    it 'Should render a complex document', (done) ->
        aglio.render blueprint, 'default', (err, html) ->
            if err then return done(err)

            assert html

            # Ensure include works
            assert html.indexOf 'This is content that was included'

            done()

    it 'Should render mixed line endings and tabs properly', (done) ->
        temp = '# GET /message\r\n+ Response 200 (text/plain)\r\r\t\tHello!\n'
        aglio.render temp, 'default', done

    it 'Should render a custom template by filename', (done) ->
        template = path.join(root, 'test', 'test.jade')
        aglio.render '# Blueprint', template, (err, html) ->
            if err then return done(err)

            assert html

            done()

    it 'Should return warnings with filtered input', (done) ->
        temp = '# GET /message\r\n+ Response 200 (text/plain)\r\r\t\tHello!\n'
        filteredTemp = temp.replace(/\r\n?/g, '\n').replace(/\t/g, '    ')

        aglio.render temp, 'default', (err, html, warnings) ->
            if err then return done(err)

            assert.equal filteredTemp, warnings.input

            done()

    it 'Should render from/to files', (done) ->
        src = path.join root, 'example.apib'
        dest = path.join root, 'example.html'
        aglio.renderFile src, dest, {}, done

    it 'Should render from stdin', (done) ->
        sinon.stub process.stdin, 'read', -> '# Hello\n'

        setTimeout -> process.stdin.emit 'readable', 1

        aglio.renderFile '-', 'example.html', 'default', (err) ->
            if err then return done(err)

            assert process.stdin.read.called
            process.stdin.read.restore()
            process.stdin.removeAllListeners()

            done()

    it 'Should render to stdout', (done) ->
        sinon.stub console, 'log'

        aglio.renderFile path.join(root, 'example.apib'), '-', 'default', (err) ->
            if err
                console.log.restore()
                return done(err)

            assert console.log.called
            console.log.restore()

            done()

    it 'Should compile from/to files', (done) ->
        src = path.join root, 'example.apib'
        dest = path.join root, 'example-compiled.apib'
        aglio.compileFile src, dest, done

    it 'Should compile from stdin', (done) ->
        sinon.stub process.stdin, 'read', -> '# Hello\n'

        setTimeout -> process.stdin.emit 'readable', 1

        aglio.compileFile '-', 'example-compiled.apib', (err) ->
            if err then return done(err)

            assert process.stdin.read.called
            process.stdin.read.restore()
            process.stdin.removeAllListeners()

            done()

    it 'Should compile to stdout', (done) ->
        sinon.stub console, 'log'

        aglio.compileFile path.join(root, 'example.apib'), '-', (err) ->
            if err then return done(err)

            assert console.log.called
            console.log.restore()

            done()

    it 'Should support legacy theme names', (done) ->
        aglio.render '', template: 'flatly', (err, html) ->
            if err then return done(err)

            assert html

            done()

    it 'Should error on missing input file', (done) ->
        aglio.renderFile 'missing', 'output.html', 'default', (err, html) ->
            assert err

            aglio.compileFile 'missing', 'output.apib', (err) ->
                assert err
                done()

    it 'Should error on bad template', (done) ->
        aglio.render blueprint, 'bad', (err, html) ->
            assert err

            done()

    it 'Should error on drafter failure', (done) ->
        sinon.stub protagonist, 'parse', (content, options, callback) ->
            callback 'error'

        aglio.render blueprint, 'default', (err, html) ->
            assert err

            protagonist.parse.restore()

            done()

    it 'Should error on file read failure', (done) ->
        sinon.stub fs, 'readFile', (filename, options, callback) ->
            callback 'error'

        aglio.renderFile 'foo', 'bar', 'default', (err, html) ->
            assert err

            fs.readFile.restore()

            done()

    it 'Should error on file write failure', (done) ->
        sinon.stub fs, 'writeFile', (filename, data, callback) ->
            callback 'error'

        aglio.renderFile 'foo', 'bar', 'default', (err, html) ->
            assert err

            fs.writeFile.restore()

            done()

    it 'Should error on non-file failure', (done) ->
        sinon.stub aglio, 'render', (content, template, callback) ->
            callback 'error'

        aglio.renderFile path.join(root, 'example.apib'), 'bar', 'default', (err, html) ->
            assert err

            aglio.render.restore()

            done()

describe 'Executable', ->
    it 'Should print a version', (done) ->
        sinon.stub console, 'log'

        bin.run version: true, (err) ->
            assert console.log.args[0][0].match /aglio \d+/
            assert console.log.args[1][0].match /olio \d+/
            console.log.restore()
            done(err)

    it 'Should render a file', (done) ->
        sinon.stub console, 'error'

        sinon.stub aglio, 'renderFile', (i, o, t, callback) ->
            warnings = [
                {
                    code: 1
                    message: 'Test message'
                    location: [
                        {
                            index: 0
                            length: 1
                        }
                    ]
                }
            ]
            warnings.input = 'test'
            callback null, warnings

        bin.run {}, (err) ->
            assert err

        bin.run i: path.join(root, 'example.apib'), o: '-', ->
            console.error.restore()
            aglio.renderFile.restore()
            done()

    it 'Should compile a file', (done) ->
        sinon.stub aglio, 'compileFile', (i, o, callback) ->
            callback null

        bin.run c: 1, i: path.join(root, 'example.apib'), o: '-', ->
            aglio.compileFile.restore()
            done()

    it 'Should start a live preview server', (done) ->
        @timeout 5000

        sinon.stub aglio, 'render', (i, t, callback) ->
            callback null, 'foo'

        sinon.stub http, 'createServer', (handler) ->
            listen: (port, host, cb) ->
                console.log 'calling listen'
                # Simulate requests
                req =
                    url: '/favicon.ico'
                res =
                    end: (data) ->
                        assert not data
                handler req, res

                req =
                    url: '/'
                res =
                    writeHead: (status, headers) -> false
                    end: (data) ->
                        aglio.render.restore()
                        cb()
                        file = fs.readFileSync 'example.apib', 'utf8'
                        setTimeout ->
                            fs.writeFileSync 'example.apib', file, 'utf8'
                            setTimeout ->
                                console.log.restore()
                                done()
                            , 500
                        , 500
                handler req, res

        sinon.stub console, 'log'
        sinon.stub console, 'error'

        bin.run s: true, (err) ->
            console.error.restore()
            assert err

            bin.run i: path.join(root, 'example.apib'), s: true, p: 3000, h: 'localhost', (err) ->
                assert.equal err, null
                http.createServer.restore()

    it 'Should support custom Jade template shortcut', (done) ->
        sinon.stub console, 'log'

        bin.run i: path.join(root, 'example.apib'), t: 'test.jade', o: '-', (err) ->
            console.log.restore()
            done(err)

    it 'Should handle theme load errors', (done) ->
        sinon.stub console, 'error'
        sinon.stub aglio, 'getTheme', ->
            throw new Error('Could not load theme')

        bin.run template: 'invalid', (err) ->
            console.error.restore()
            aglio.getTheme.restore()
            assert err
            done()

    it 'Should handle rendering errors', (done) ->
        sinon.stub aglio, 'renderFile', (i, o, t, callback) ->
            callback
                code: 1
                message: 'foo'
                input: 'foo bar baz'
                location: [
                    { index: 1, length: 1 }
                ]

        sinon.stub console, 'error'

        bin.run i: path.join(root, 'example.apib'), o: '-', ->
            assert console.error.called

            console.error.restore()
            aglio.renderFile.restore()

            done()
