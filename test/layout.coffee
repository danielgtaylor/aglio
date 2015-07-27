{assert} = require 'chai'
theme = require '../lib/main'

describe 'Layout', ->
  it 'Should include API title & description', (done) ->
    ast =
      name: 'Test API'
      description: 'I am a [test](http://test.com/) API.'

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'Test API'
      assert.include html, 'I am a <a href="http://test.com/">test</a> API.'
      done()

  it 'Should render custom code in markdown', (done) ->
    ast =
      description: 'Test\n\n```coffee\na = 1\n```\n'

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'a = <span class="hljs-number">1</span>'
      done()

  it 'Should highlight unfenced code blocks', (done) ->
    ast =
      description: 'Test\n\n    var a = 1;\n'

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, '<span class="hljs-number">1</span>'
      done()

  it 'Should auto-link headings in markdown', (done) ->
    ast =
      description: '# Custom Heading'

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, '<h1 id="header-custom-heading"'
      assert.include html, '<a class="permalink" href="#header-custom-heading"'
      done()

  it 'Should generate unique header ids', (done) ->
    ast =
      description: '# Custom heading\n## Custom heading\n## Custom heading\n'

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, '"header-custom-heading"'
      assert.include html, '"header-custom-heading-1"'
      assert.include html, '"header-custom-heading-2"'
      done()

  it 'Should include API hostname', (done) ->
    ast =
      metadata: [
        {name: 'HOST', value: 'http://foo.com/'}
      ]

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'http://foo.com/'
      done()

  it 'Should include resource group name & description', (done) ->
    ast =
      resourceGroups: [
        name: 'Frobs'
        description: 'A list of *Frobs*'
        resources: []
      ]

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'Frobs'
      assert.include html, 'A list of <em>Frobs</em>'
      done()

  it 'Should include resource information', (done) ->
    ast =
      resourceGroups: [
        name: 'Frobs'
        resources: [
          name: 'Test Resource'
          description: 'Test *description*'
          actions: []
        ]
      ]

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'Test Resource'
      assert.include html, 'Test <em>description</em>'
      done()

  it 'Should include action information', (done) ->
    ast =
      resourceGroups: [
        name: 'TestGroup'
        resources: [
          name: 'TestResource'
          uriTemplate: '/resource/{idParam}{?param%2Dname*,param2Name}'
          parameters: [
            name: 'idParam'
            description: 'Id parameter description'
            values: []
          ]
          actions: [
            name: 'Test Action',
            description: 'Test *description*'
            method: 'GET'
            parameters: [
              name: 'param-name'
              description: 'Param *description*'
              type: 'bool'
              required: true
              values: [
                {value: 'test%2Dchoice'}
              ]
            ]
            examples: [
              name: ''
              description: ''
              requests: [
                name: '200'
                headers: []
                body: '{"error": true}'
                schema: ''
              ]
              responses: []
            ]
          ]
        ]
      ]

    theme.render ast, (err, html) ->
      if err then return done err
      assert.include html, 'Test Action'
      assert.include html, 'Test <em>description</em>'
      assert.include html, 'GET'
      assert.include html, '/resource/{idParam}{?param-name*}'
      assert.include html, 'idParam'
      assert.include html, 'Id parameter description'
      assert.include html, 'param-name'
      assert.include html, 'Param <em>description</em>'
      assert.include html, 'bool'
      assert.include html, 'required'
      assert.include html, 'true'
      assert.include html, 'test-choice'
      done()
