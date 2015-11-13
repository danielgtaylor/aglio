# Handle MSON inheritance. This is interesting because certain attributes,
# items, members, etc can be overridden. For example, the `id` property is
# overridden to be any valid `string` below:
#
# # My Type
# + id (number)
# + name (string)
#
# # Another Type (My Type)
# + id (string)

# Make sure all members are unique, removing all duplicates before the last
# occurence of the member key name.
uniqueMembers = (content) ->
  known = []
  i = content.length - 1
  while i >= 0
    if content[i].element is 'member'
      key = content[i].content.key.content
      if known.indexOf(key) isnt -1
        content.splice(i, 1)
        continue
      known.push key
    i--

# Have `element` inherit from `base`.
module.exports = (base, element) ->
  # First, we do a deep copy of the base (parent) element
  combined = JSON.parse(JSON.stringify(base))

  # Next, we copy or overwrite any metadata and attributes
  if element.meta
    combined.meta ?= {}
    combined.meta[key] = value for own key, value of element.meta
  if element.attributes
    combined.attributes ?= {}
    combined.attributes[key] = value for own key, value of element.attributes

  # Lastly, we combine the content if we can. For simple types, this means
  # overwriting the content. For arrays it adds to the content list and for
  # objects is adds *or* overwrites (if an existing key already exists).
  if element.content
    if combined.content?.push or element.content?.push
      # This could be an object or array
      combined.content ?= []
      for item in element.content
        combined.content.push item

      if combined.content.length and combined.content[0].element is 'member'
        # This is probably an object - remove duplicate keys!
        uniqueMembers combined.content
    else
      # Not an array or object, just overwrite the content
      combine.content = element.content
  combined
