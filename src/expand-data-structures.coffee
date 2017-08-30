# When named type inheriting from another data structure,
# all of the parents properties will be inherited
#
# get inherited properties for refracted MSON input

module.exports = expandDS = (root, dataStructures) ->
  # First, we do a deep copy of the clonedRoot element
  clonedRoot = JSON.parse(JSON.stringify(root))

  switch clonedRoot.element
    when 'boolean', 'string', 'number', 'enum'
      break
    when 'member'
      valueOfContent = clonedRoot['content']['value']
      newValue = expandDS(valueOfContent, dataStructures)
      clonedRoot.content['value'] = newValue
    when 'object'
      for item, index in clonedRoot.content
        clonedRoot.content[index] = expandDS(item, dataStructures)
    when 'array'
      if clonedRoot.content
        for valueOfArray, keyOfArray in clonedRoot.content
          newValue = expandDS(valueOfArray, dataStructures)
          # only show one element in array
          clonedRoot.content = []
          clonedRoot.content[keyOfArray] = newValue
          break
    else
      ref = dataStructures[clonedRoot.element]
      if ref
        newRoot = expandDS(ref, dataStructures)
        if clonedRoot.content
          for valueOfArray in clonedRoot.content
            newValue = expandDS(valueOfArray, dataStructures)
            newRoot.content.push newValue
        clonedRoot = newRoot

  return clonedRoot
