# This is an extremely simple JSON Schema generator given refracted MSON input.
# It handles the following:
#
# * Simple types, enums, arrays, objects
# * Property descriptions
# * Required, default properties
# * References
# * Mixins (Includes)
# * Arrays with members of different types
#
# It is missing support for many advanced features.
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
        schema.items = 'anyOf': items
    when 'object'
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
          for item in ref.content
            properties.push item
          continue
        else if member.element == 'select'
          # TODO: Not supported yet, but we want to skip these.
          continue
        key = member.content.key.content
        schema.properties[key] = renderSchema(
          member.content.value, dataStructures)
        if member.meta?.description?
          schema.properties[key].description = member.meta.description
        if member.attributes?.typeAttributes
          typeAttr = member.attributes.typeAttributes
          if typeAttr.indexOf('required') isnt -1
            required.push key
      if required.length
        schema.required = required
    else
      ref = dataStructures[root.element]
      if ref
        schema = renderSchema(ref, dataStructures)
  schema
