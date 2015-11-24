{assert} = require 'chai'
theme = require '../lib/main'

examples = [
  {
    uriTemplate: '/resource/{path}'
    parameters: [
      {
        name: 'path'
      }
    ]
    exampleURI: [
      '/resource/'
      {attribute: 'path'}
    ]
  }

  {
    uriTemplate: '/resource/{+reserved}'
    parameters: [
      {
        name: 'reserved'
        example: 'this/that'
      }
    ]
    exampleURI: [
      '/resource/'
      {attribute: 'this/that', title: 'reserved'}
    ]
  }

  {
    uriTemplate: '/resource{?greeting,name*}'
    parameters: [
      {
        name: 'greeting'
        example: 'hello'
      }
      {
        name: 'name'
        example: 'world'
      }
    ]
    exampleURI: [
      '/resource'
      {operator: '?', attribute: 'greeting', literal: 'hello'}
      {operator: '&', attribute: 'name', literal: 'world'}
    ]
  }

  {
    uriTemplate: '/resource{?greeting}{&name}'
    parameters: [
      {
        name: 'greeting'
        example: 'hello'
      }
      {
        name: 'name'
        example: 'world'
      }
    ]
    exampleURI: [
      '/resource'
      {operator: '?', attribute: 'greeting', literal: 'hello'}
      {operator: '&', attribute: 'name', literal: 'world'}
    ]
  }

  {
    uriTemplate: '/resource{?greeting}{+something}'
    parameters: [
      {
        name: 'greeting'
        example: 'hello'
      }
      {
        name: 'something'
        example: 'with/slash'
      }
    ]
    exampleURI: [
      '/resource'
      {operator: '?', attribute: 'greeting', literal: 'hello'}
      {title: 'something', attribute: 'with/slash'}
    ]
  }
]

addParameterDefaults = (example) ->
  example.parameters = for parameter in example.parameters
    {
      name: parameter.name
      description: parameter.description or ''
      type: parameter.type or 'string'
      required: parameter.required or false
      values: parameter.values or []
      example: parameter.example or ''
      defaultValue: parameter.defaultValue or ''
    }

generateAST = (example) ->
  example.ast =
    resourceGroups: [
      name: 'TestGroup'
      resources: [
        name: 'TestResource'
        uriTemplate: example.uriTemplate
        parameters: example.parameters
        actions: [
          name: 'Test Action',
          description: 'Test *description*'
          method: 'GET'
          parameters: []
          examples: [
            name: ''
            description: ''
            requests: [
              name: '200'
              headers: []
              body: ''
              schema: ''
            ]
            responses: []
          ]
        ]
      ]
    ]

createExampleURI = (example) ->
  exampleURI = ''
  for segment in example.exampleURI
    if typeof segment is 'string'
      exampleURI += segment
    else
      if segment.operator
        exampleURI += segment.operator
      if segment.literal
        exampleURI += "<span class=\"hljs-attribute\">#{segment.attribute}=</span><span class=\"hljs-literal\">#{segment.literal}</span>"
      else
        exampleURI += "<span class=\"hljs-attribute\" title=\"#{segment.title or segment.attribute}\">#{segment.attribute}</span>"
  example.exampleURI = exampleURI


describe 'URI Rendering', ->
  examples.forEach (example) ->
    addParameterDefaults example
    generateAST example
    createExampleURI example

    it "Should render #{example.uriTemplate}", (done) ->
      theme.render example.ast, (err, html) ->
        if err then return done err
        assert.include html, example.uriTemplate.replace /&/g, '&amp;'
        assert.include html, example.exampleURI
        done()
