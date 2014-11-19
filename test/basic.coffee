aglio = require '../lib/main'
assert = require 'assert'
bin = require '../lib/bin'
fs = require 'fs'
http = require 'http'
jade = require 'jade'
path = require 'path'
protagonist = require 'protagonist'
sinon = require 'sinon'

root = path.dirname(__dirname)

blueprint = fs.readFileSync path.join(root, 'example.md'), 'utf-8'

describe 'API Blueprint Renderer', ->
    it 'Should get a list of templates', (done) ->
        aglio.getTemplates (err, templates) ->
            if err then return done(err)

            assert templates.length
            done()

    it 'Should get a list of templates', (done) ->
        sinon.stub fs, 'readdir', (name, callback) ->
            callback 'error'

        aglio.getTemplates (err, templates) ->
            assert err

            fs.readdir.restore()

            done()

    it 'Should render blank string', (done) ->
        aglio.render '', template: 'default', locals: {foo: 1}, (err, html) ->
            if err then return done(err)

            assert html

            done()

    it 'Should render a complex document', (done) ->
        aglio.render blueprint, 'default', (err, html) ->
            if err then return done(err)

            assert html

            done()

    it 'Should render mixed line endings and tabs properly', (done) ->
        temp = '# GET /message\r\n+ Response 200 (text/plain)\r\r\t\tHello!\n'
        aglio.render temp, 'default', done

    it 'Should render a custom template by filename', (done) ->
        template = path.join(root, 'templates', 'default.jade')
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
        src = path.join root, 'example.md'
        dest = path.join root, 'example.html'
        aglio.renderFile src, dest, {}, done

    it 'Should render from stdin', (done) ->
        sinon.stub process.stdin, 'read', -> '# Hello\n'

        setTimeout -> process.stdin.emit 'readable', 1

        aglio.renderFile '-', 'example.html', 'default', (err) ->
            if err then return done(err)

            assert process.stdin.read.called
            process.stdin.read.restore()

            done()

    it 'Should render to stdout', (done) ->
        sinon.stub console, 'log'

        aglio.renderFile path.join(root, 'example.md'), '-', 'default', (err) ->
            if err then return done(err)

            assert console.log.called
            console.log.restore()

            done()

    it 'Should error on missing input file', (done) ->
        aglio.renderFile 'missing', 'output.html', 'default', (err, html) ->
            assert err

            done()

    it 'Should error on bad template', (done) ->
        aglio.render blueprint, 'bad', (err, html) ->
            assert err

            done()

    it 'Should error on protagonist failure', (done) ->
        sinon.stub protagonist, 'parse', (content, callback) ->
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

        aglio.renderFile path.join(root, 'example.md'), 'bar', 'default', (err, html) ->
            assert err

            aglio.render.restore()

            done()

    it 'Should parse action uris', (done) ->
        mock = [resources: [
            {
                uriTemplate: "/api/resource/{id}{?constraint,skip}"
                actions: [
                    {
                        parameters: [
                            name: 'id'
                        ]
                    }
                    {
                        parameters: [
                            {
                                name: 'constraint'
                            }
                            {
                                name: 'skip'
                            }
                        ]
                    }
                ]
            }
        ]]

        aglio.resolveActionUris mock
        assert mock[0].resources[0].actions[0].uriTemplate == '/api/resource/{id}'
        assert mock[0].resources[0].actions[1].uriTemplate == '/api/resource/{?constraint,skip}'
        done()

describe 'Executable', ->
    it 'Should list templates', (done) ->
        sinon.stub console, 'log'

        bin.run l: true, ->
            console.log.restore()
            done()

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

        bin.run i: path.join(root, 'example.md'), o: '-', ->
            console.error.restore()
            aglio.renderFile.restore()
            done()

    it 'Should start a live preview server', (done) ->
        @timeout 5000

        sinon.stub aglio, 'render', (i, t, callback) ->
            callback null, 'foo'

        sinon.stub http, 'createServer', (handler) ->
            listen: (port, host, cb) ->
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
                        file = fs.readFileSync 'example.md', 'utf8'
                        setTimeout ->
                            fs.writeFileSync 'example.md', file, 'utf8'
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

        bin.run i: path.join(root, 'example.md'), s: true, p: 3000, h: 'localhost', ->
            http.createServer.restore()

    it 'Should handle errors', (done) ->
        sinon.stub aglio, 'renderFile', (i, o, t, callback) ->
            callback
                code: 1
                message: 'foo'
                input: 'foo bar baz'
                location: [
                    { index: 1, length: 1 }
                ]

        sinon.stub console, 'error'

        bin.run i: path.join(root, 'example.md'), o: '-', ->
            assert console.error.called

            console.error.restore()
            aglio.renderFile.restore()

            done()
