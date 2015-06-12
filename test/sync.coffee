aglio = require '../lib/main'
assert = require 'assert'
fs = require 'fs'
path = require 'path'
protagonist = require 'protagonist'
sinon = require 'sinon'

root = path.dirname(__dirname)

blueprint = fs.readFileSync path.join(root, 'example.md'), 'utf-8'

describe 'API Blueprint Synchronous Renderer', ->

    it 'Should render blank string', ->
        assert aglio.renderSync '', template: 'default', locals: {foo: 1}

    it 'Should render a complex document', ->
        html = aglio.renderSync blueprint, 'default'

        assert html
        assert html.indexOf 'This is content that was included'

    it 'Should render mixed line endings and tabs properly', ->
        temp = '# GET /message\r\n+ Response 200 (text/plain)\r\r\t\tHello!\n'
        aglio.renderSync temp, 'default'

    it 'Should render a custom template by filename', ->
        template = path.join(root, 'templates', 'default.jade')
        assert aglio.renderSync '# Blueprint', template

    it 'Should error on bad template', ->
        assert.throws ->
            aglio.renderSync blueprint, 'bad'

    it 'Should error on protagonist failure', ->
        sinon.stub protagonist, 'parseSync', (content) ->
            throw new Error('test')

        assert.throws ->
            aglio.renderSync blueprint, 'default'

        protagonist.parseSync.restore()
