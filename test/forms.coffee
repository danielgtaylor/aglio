{assert} = require 'chai'
theme = require '../lib/main'

describe 'Forms', ->
  it 'Should not generate form fields when disabled', (done) ->

    theme.render ast, {themeForms: false}, (err, html) ->
      if err then return done err

      assert.notInclude html, '<input'
      assert.notInclude html, '<select'
      assert.notInclude html, '<textarea'
      assert.notInclude html, 'Try it out!'
      assert.notInclude html, 'class="click-to-fill"'

      done()

  it 'Should use the formsBaseUri option', (done) ->

    theme.render ast, {themeForms: true, themeFormsBaseUri: 'http://example.com/rest/'}, (err, html) ->
      if err then return done err
      assert.include html, '<input type="hidden" name="__uri" value="http://example.com/rest/test">'
      done()

  it 'Should use the HOST metadata when there is no formsBaseUri option', (done) ->

    theme.render ast, {themeForms: true}, (err, html) ->
      if err then return done err
      assert.include html, '<input type="hidden" name="__uri" value="http://acme.com/test">'
      done()

  it 'Should generate form fields', (done) ->

    theme.render ast, {themeForms: true}, (err, html) ->
      if err then return done err

      # GET

      expectSelect html, 'boolean', true, ['true', 'false']
      expectClickToFill html, 'boolean', 'true'

      expectSelect html, 'optional_boolean', false, ['', 'true', 'false']
      expectClickToFill html, 'optional_boolean', 'true'

      expectInput html, 'number', 'number', true, 123
      expectClickToFill html, 'number', 123

      expectInput html, 'optional', 'text'
      expectClickToFill html, 'optional', 'example'

      expectInput html, 'default', 'text', true, 'default'
      expectNoClickToFill html, 'default'

      expectInput html, 'example', 'text', true, 'example'
      expectClickToFill html, 'example', 'example'

      expectInput html, 'default_example', 'text', true, 'default'
      expectClickToFill html, 'default_example', 'example'

      expectSelect html, 'enum', true, ['one', 'two']
      expectClickToFill html, 'enum', 'one', 'code'
      expectClickToFill html, 'enum', 'two', 'code'
      expectClickToFill html, 'enum', 'two'

      expectSelect html, 'optional_enum', false, ['', 'one', 'two']
      expectClickToFill html, 'optional_enum', 'one', 'code'
      expectClickToFill html, 'optional_enum', 'two', 'code'
      expectClickToFill html, 'optional_enum', 'two'

      expectSelect html, 'explode_enum', true, ['one', 'two'], true
      expectClickToFill html, 'explode_enum', 'one', 'code'
      expectClickToFill html, 'explode_enum', 'two', 'code'
      expectClickToFill html, 'explode_enum', 'one'

      # POST

      assert.include html, '<select name="__request" class="request"><option value="0">Text Message</option><option value="1">JSON Message</option></select>'
      assert.include html, '<textarea name="__body" id="test-post-__body" class="body">Dave\n</textarea>'

      done()


expectSelect = (html, name, required, options, multiple) ->
  required = if required then ' required' else ''
  multiple = if multiple then ' multiple' else ''
  assert.include html, "<select name=\"#{name}\" id=\"test-get-#{name}\"#{required}#{multiple} class=\"parameter\">#{createOptions options}</select>"

createOptions = (options) ->
  result = ''
  for option in options
    if option
      result += "<option value=\"#{option}\">#{option}</option>"
    else
      result += "<option></option>"
  return result

expectInput = (html, name, type, required, value) ->
  required = if required then ' required' else ''
  assert.include html, "<input type=\"#{type || 'text'}\" name=\"#{name}\" id=\"test-get-#{name}\" value=\"#{value || ''}\"#{required} class=\"parameter\">"

expectClickToFill = (html, name, example, tag) ->
  tag ?= 'span'
  assert.include html, "<#{tag} data-fill-target=\"test-get-#{name}\" class=\"click-to-fill\">#{example}</#{tag}>"

expectNoClickToFill = (html, name) ->
  assert.notInclude html, "<span data-fill-target=\"test-get-#{name}\""


ast = {
  metadata: [
    {
      name: 'HOST',
      value: 'http://acme.com'
    }
  ]
  name: ''
  description: ''
  resourceGroups: [
    {
      name: ''
      description: ''
      resources: [
        {
          name: 'Test'
          description: ''
          uriTemplate: '/test'
          model: {}
          parameters: []
          actions: [
            {
              name: 'Retrieve'
              description: 'Test get.\n\n'
              method: 'GET'
              parameters: [
                {
                  name: 'boolean'
                  description: 'A boolean parameter'
                  type: 'boolean'
                  required: true
                  default: ''
                  example: 'true'
                  values: []
                }
                {
                  name: 'optional_boolean'
                  description: 'A boolean parameter'
                  type: 'boolean'
                  required: false
                  default: ''
                  example: 'true'
                  values: []
                }
                {
                  name: 'number'
                  description: 'A number parameter'
                  type: 'number'
                  required: true
                  default: ''
                  example: '123'
                  values: []
                }
                {
                  name: 'optional'
                  description: 'An optional string parameter with an example'
                  type: 'string'
                  required: false
                  default: ''
                  example: 'example'
                  values: []
                }
                {
                  name: 'default'
                  description: 'A string parameter with a default value but no example'
                  type: 'string'
                  required: true
                  default: 'default'
                  example: ''
                  values: []
                }
                {
                  name: 'example'
                  description: 'A string parameter with an example but no default'
                  type: 'string'
                  required: true
                  default: ''
                  example: 'example'
                  values: []
                }
                {
                  name: 'default_example'
                  description: 'A string parameter with an example and a default'
                  type: 'string'
                  required: true
                  default: 'default'
                  example: 'example'
                  values: []
                }
                {
                  name: 'enum'
                  description: 'An enum parameter'
                  type: 'string'
                  required: true
                  default: ''
                  example: 'two'
                  values: [
                    { value: 'one' }
                    { value: 'two' }
                  ]
                }
                {
                  name: 'optional_enum'
                  description: 'An optional enum parameter'
                  type: 'string'
                  required: false
                  default: ''
                  example: 'two'
                  values: [
                    { value: 'one' }
                    { value: 'two' }
                  ]
                }
                {
                  name: 'explode_enum'
                  description: 'An explosive enum parameter'
                  type: 'string'
                  required: true
                  default: ''
                  example: 'one'
                  values: [
                    { value: 'one' }
                    { value: 'two' }
                  ]
                }
              ]
              attributes:
                relation: ''
                uriTemplate: '/test{?resource}{&boolean}{&optional_boolean}{&number}{&optional}{&default}{&example}{&default_example}{&enum}{&optional_enum}{&explode_enum*}'
              content: []
              examples: [
                {
                  name: ''
                  description: ''
                  requests: []
                  responses: [
                    {
                      name: '200'
                      description: ''
                      headers: [
                        {
                          name: 'Content-Type'
                          value: 'application/json'
                        }
                      ]
                      body: ''
                      schema: ''
                      content: []
                    }
                  ]
                }
              ]
            }
            {
              name: 'Post'
              description: 'Test post.\n\n'
              method: 'POST'
              parameters: []
              attributes:
                relation: ''
                uriTemplate: ''
              content: []
              examples: [
                {
                  name: ''
                  description: ''
                  requests: [
                    {
                      name: 'Text Message'
                      description: ''
                      headers: [
                        {
                          name: 'Content-Type'
                          value: 'text/plain'
                        }
                      ]
                      body: 'Dave\n'
                      schema: ''
                      content: [
                        {
                          attributes:
                            role: 'bodyExample'
                          content: 'Dave\n'
                        }
                      ]
                    }
                  ]
                  responses: [
                    {
                      name: '200'
                      description: ''
                      headers: [
                        {
                          name: 'Content-Type'
                          value: 'text/plain'
                        }
                      ]
                      body: 'Hello Dave\n'
                      schema: ''
                      content: [
                        {
                          attributes:
                            role: 'bodyExample'
                          content: 'Hello Dave\n'
                        }
                      ]
                    }
                  ]
                }
                {
                  name: ''
                  description: ''
                  requests: [
                    {
                      name: 'JSON Message'
                      description: ''
                      headers: [
                        {
                          name: 'Content-Type'
                          value: 'application/json'
                        }
                      ]
                      body: '{\n    \'name\': \'Dave\',\n    \'greeting\': \'Hi\'\n}\n'
                      schema: ''
                      content: [
                        {
                          attributes:
                            role: 'bodyExample'
                          content: '{\n    \'name\': \'Dave\',\n    \'greeting\': \'Hi\'\n}\n'
                        }
                      ]
                    }
                  ]
                  responses: [
                    {
                      name: '200'
                      description: ''
                      headers: [
                        {
                          name: 'Content-Type'
                          value: 'application/json'
                        }
                      ]
                      body: '{\n    \'message\': \'Hi Dave\'\n}\n'
                      schema: ''
                      content: [
                        {
                          attributes:
                            role: 'bodyExample'
                          content: '{\n    \'message\': \'Hi Dave\'\n}\n'
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
          content: []
        }
      ]
    }
  ]
}