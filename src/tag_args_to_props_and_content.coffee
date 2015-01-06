helpers         = require './helpers'

###
###
module.exports = ( args ) ->
  # we need to merge properties
  args = args.concat() # operate on a copy
  # last argument can be the content
  # this is a heuristic
  has_content = no
  content = undefined
  if is_content args[args.length - 1]
    content = args.pop()
    has_content = yes

  # merge all args
  props = {}
  for arg in args when typeof arg is 'object'
    for own k, v of arg
      props[k] = v

  result = {}
  result.props   = props
  result.content = content if has_content
  result

is_content = ( v ) ->
  # everything that is not an object is considered content
  return yes unless typeof v is 'object'
  # null ( which is of type 'object' ) is content as well
  return yes if v is null
  # Arrays are content
  return yes if v instanceof Array
  # some special objects are also content
  return yes if helpers.is_ext_component v
  return yes if helpers.is_dom_node v
  return yes if helpers.is_jquery_obj v
  no
