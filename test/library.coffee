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
      theme.render {}, themeColors: 'styles/colors-default.less', done

    it 'Should error on missing colors', (done) ->
      theme.render {}, themeColors: '/bad/path.less', (err, html) ->
        assert.ok err
        done()

    it 'Should accept a custom style', (done) ->
      theme.render {}, themeStyle: 'styles/layout-default.less', done

    it 'Should error on missing style', (done) ->
      theme.render {}, themeStyle: '/bad/style.less', (err, html) ->
        assert.ok err
        done()

    it 'Should error on missing layout', (done) ->
      theme.render {}, themeLayout: '/bad/path.jade', (err, html) ->
        assert.ok err
        done()

    it 'Should benchmark', (done) ->
      old = process.env.BENCHMARK
      process.env.BENCHMARK = true
      theme.render {}, (err, html) ->
        process.env.BENCHMARK = old
        done err
