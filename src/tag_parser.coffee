head_parser  = require './tag_head_parser'
props_parser = require './tag_props_parser'
helpers      = require './helpers'


module.exports = parse_many = ( heads, args, default_ns = 'html' ) ->
  heads = head_parser.as_many_tag_heads heads, default_ns
  
  if heads.length is 0
    throw new Error 'No valid heads found'
  # the first tags only have a head
  # the last one has properties
  last_head = heads.pop()
  try
    last_head_properties = args_to_properties args
  catch e
    throw new Error 'error while parsing properties for tag ' + last_head.toString() + ' : ' + e.message
  
  last_head_properties.head = last_head

  # TODO: NSChange tags should not have any properties, listeners, etc. only content

  result = []
  result.push head: head for head in heads
  result.push last_head_properties
  result


args_to_properties = ( args ) ->
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

  # parse properties
  props = props_parser props

  # add content
  props.content = content if has_content
  props



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



test = ->
  console.log parse_many 'a', [ {href: '#'} ]
  console.log parse_many 'ext:panel ul li#foo', [ {href: '#'}, { $color: 'red', '.active': '' }, ( -> ) ]
  ###
[ { properties: { href: '#' }, head: { tag: 'a', ns: 'html' } } ]
[ { head: { tag: 'panel', ns: 'ext' } },
  { head: { tag: 'ul', ns: 'html' } },
  { properties: { href: '#' },
    styles: { color: 'red' },
    classflags: { active: true },
    content: [Function],
    head: { tag: 'li', ns: 'html' } } ]
  ###



