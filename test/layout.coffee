{assert} = require 'chai'
theme = require '../lib/main'

describe 'Layout', ->
  it 'Should include API title & description', ->
    ast =
      name: 'Test API'
      description: 'I am a [test](http://test.com/) API.'

    html = theme.render ast
    assert.include html, 'Test API'
    assert.include html, 'I am a <a href="http://test.com/">test</a> API.'

  it 'Should render custom code in markdown', ->
    ast =
      description: 'Test\n\n```coffee\na = 1\n```\n'

    html = theme.render ast
    assert.include html, 'a = <span class="hljs-number">1</span>'

  it 'Should auto-link headings in markdown', ->
    ast =
      description: '# Custom Heading'

    html = theme.render ast
    assert.include html, '<h1 id="header-custom-heading">'
    assert.include html, '<a class="permalink" href="#header-custom-heading">'

  it 'Should include API hostname', ->
    ast =
      metadata: [
        {name: 'HOST', value: 'http://foo.com/'}
      ]

    html = theme.render ast
    assert.include html, 'http://foo.com/'

  it 'Should include resource group name & description', ->
    ast =
      resourceGroups: [
        name: 'Frobs'
        description: 'A list of *Frobs*'
        resources: []
      ]

    html = theme.render ast
    assert.include html, 'Frobs'
    assert.include html, 'A list of <em>Frobs</em>'

  it 'Should include resource information', ->
    ast =
      resourceGroups: [
        name: 'Frobs'
        resources: [
          name: 'Test Resource'
          description: 'Test *description*'
          actions: []
        ]
      ]

    html = theme.render ast
    assert.include html, 'Test Resource'
    assert.include html, 'Test <em>description</em>'

  it 'Should include action information', ->
    ast =
      resourceGroups: [
        name: 'TestGroup'
        resources: [
          name: 'TestResource'
          parameters: []
          actions: [
            name: 'Test Action',
            description: 'Test *description*'
            method: 'GET'
            parameters: [
              name: 'paramName'
              description: 'Param *description*'
              type: 'bool'
              required: true
              values: []
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

    html = theme.render ast
    assert.include html, 'Test Action'
    assert.include html, 'Test <em>description</em>'
    assert.include html, 'GET'
    assert.include html, 'paramName'
    assert.include html, 'Param <em>description</em>'
    assert.include html, 'bool'
    assert.include html, 'required'
    assert.include html, 'true'
