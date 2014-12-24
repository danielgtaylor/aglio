{assert} = require 'chai'
jade = require 'jade'
theme = require '../lib/main'

describe 'Library', ->
  describe 'Config', ->
    it 'Should allow getting config', ->
      config = theme.getConfig()
      assert.ok config

    it 'Should contain supported format version', ->
      config = theme.getConfig()
      assert.ok config.formats

    it 'Should contain option information', ->
      config = theme.getConfig()
      assert.ok config.options

      assert.ok config.options.length > 1
      option = config.options[0]

      assert.ok option.name
      assert.ok option.description

  describe 'Render', ->
    it 'Should not require options', (done) ->
      theme.render {}, (err, html) ->
        done err

    it 'Should accept options', (done) ->
      theme.render {}, {}, (err, html) ->
        done err

    it 'Should accept custom colors', (done) ->
      theme.render {}, colors: 'styles/colors-default.less', done

    it 'Should error on missing colors', (done) ->
      theme.render {}, colors: '/bad/path.less', (err, html) ->
        assert.ok err
        done()

    it 'Should accept a custom style', (done) ->
      theme.render {}, style: 'styles/layout-default.less', done

    it 'Should error on missing style', (done) ->
      theme.render {}, style: '/bad/style.less', (err, html) ->
        assert.ok err
        done()

    it 'Should error on missing layout', (done) ->
      theme.render {}, layout: '/bad/path.jade', (err, html) ->
        assert.ok err
        done()
