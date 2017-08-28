# When named type inheriting from another data structure,
# all of the parents properties will be inherited
#
# get inherited properties for refracted MSON input

defaultValue = (type) ->
  switch type
    when 'boolean' then true
    when 'number' then 1
    when 'string' then 'Hello, world!'

module.exports = expandDS = (root, dataStructures) ->
  switch root.element
    when 'boolean', 'string', 'number', 'enum'
      break
    when 'member'
      valueOfContent = root['content']['value']
      newValue = expandDS(valueOfContent, dataStructures)
      root.content['value'] = newValue
    when 'object'
      for item, index in root.content
        root.content[index] = expandDS(item, dataStructures)
    when 'array'
      for valueOfArray, keyOfArray in root.content
        newValue = expandDS(valueOfArray, dataStructures)
        # only show one element in array
        root.content = []
        root.content[keyOfArray] = newValue
        break
    else
      ref = dataStructures[root.element]
      if ref
        root = expandDS(ref, dataStructures)

  return root
#
#  switch root.element
#    when 'boolean', 'string', 'number'
#      if root.content? then root.content else defaultValue(root.element)
#    when 'enum' then renderExample root.content[0], dataStructures
#    when 'array'
#      for item in root.content or []
#        renderExample(item, dataStructures)
#    when 'object'
#      obj = {}
#      properties = root.content.slice(0)
#      i = 0
#      while i < properties.length
#        member = properties[i]
#        i++
#        if member.element == 'ref'
#          ref = dataStructures[member.content.href]
#          i--
#          properties.splice.apply properties, [i, 1].concat(ref.content)
#          continue
#        else if member.element == 'select'
## Note: we *always* select the first choice!
#          member = member.content[0].content[0]
#        key = member.content.key.content
#        obj[key] = renderExample(member.content.value, dataStructures)
#      obj
#    else
#      ref = dataStructures[root.element]
#      if ref
#        renderExample(inherit(ref, root), dataStructures)
