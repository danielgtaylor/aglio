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
    it 'Should not require options', ->
      theme.render {}

    it 'Should accept options', ->
      theme.render {}, {}

    it 'Should accept custom colors', ->
      theme.render {}, themeColors: 'default'

    it 'Should error on missing colors', ->
      assert.throws ->
        theme.render {}, themeColors: 'ugly-colors'

    it 'Should accept a custom style', ->
      theme.render {}, themeStyle: 'default'

    it 'Should error on missing style', ->
      assert.throws ->
        theme.render {}, themeStyle: 'ugly-style'

    it 'Should error on missing layout', ->
      assert.throws ->
        theme.render {}, themeLayout: '/bad/path.jade'

    it 'Should benchmark', ->
      err = null
      count = 0
      oldEnv = process.env.BENCHMARK
      oldWrite = process.stdout.write
      process.env.BENCHMARK = true
      process.stdout.write = -> count++
      try
        theme.render {}
        assert.ok count > 0, 'It printed something'
      catch _err
        err = _err
      finally
        process.stdout.write = oldWrite
        process.env.BENCHMARK = oldEnv
      if err then throw err
