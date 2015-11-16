# This is an extremely simple JSON Schema generator given refracted MSON input.
# It handles the following:
#
# * Simple types, enums, arrays, objects
# * Property descriptions
# * Required, default, nullable properties
# * References
# * Mixins (Includes)
# * Arrays with members of different types
# * One Of (mutually exclusive) properties
#
# It is missing support for many advanced features.
{deepEqual} = require 'assert'
inherit = require './inherit'

module.exports = renderSchema = (root, dataStructures) ->
  schema = {}
  switch root.element
    when 'boolean', 'string', 'number'
      schema.type = root.element
      if root.attributes?.default?
        schema.default = root.attributes.default
    when 'enum'
      schema.enum = []
      for item in root.content or []
        schema.enum.push item.content
    when 'array'
      schema.type = 'array'
      items = []
      for item in root.content or []
        items.push renderSchema(item, dataStructures)
      if items.length is 1
        schema.items = items[0]
      else if items.length > 1
        try
          schema.items = items.reduce (l, r) -> deepEqual(l, r) or r
        catch
          schema.items = 'anyOf': items
    when 'object', 'option'
      schema.type = 'object'
      schema.properties = {}
      required = []
      properties = root.content.slice(0)
      i = 0
      while i < properties.length
        member = properties[i]
        i++
        if member.element == 'ref'
          ref = dataStructures[member.content.href]
          i--
          properties.splice.apply properties, [i, 1].concat(ref.content)
          continue
        else if member.element == 'select'
          exclusive = []
          for option in member.content
            optionSchema = renderSchema(option, dataStructures)
            for key, prop of optionSchema.properties
              exclusive.push key
              schema.properties[key] = prop
          if not schema.allOf then schema.allOf = []
          schema.allOf.push not: required: exclusive
          continue
        key = member.content.key.content
        schema.properties[key] = renderSchema(
          member.content.value, dataStructures)
        if member.meta?.description?
          schema.properties[key].description = member.meta.description
        if member.attributes?.typeAttributes
          typeAttr = member.attributes.typeAttributes
          if typeAttr.indexOf('required') isnt -1
            if required.indexOf(key) is -1 then required.push key
          if typeAttr.indexOf('nullable') isnt -1
            schema.properties[key].type = [schema.properties[key].type, 'null']
      if required.length
        schema.required = required
    else
      ref = dataStructures[root.element]
      if ref
        schema = renderSchema(inherit(ref, root), dataStructures)

  if root.meta?.description?
    schema.description = root.meta.description

  if root.attributes?.typeAttributes
    typeAttr = root.attributes.typeAttributes
    if typeAttr.indexOf('nullable') isnt -1
      schema.type = [schema.type, 'null']
  schema
