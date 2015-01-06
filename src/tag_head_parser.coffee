htp = require 'htmltagparser'


class TagHead
  constructor: ( @tag, @ns, @id, @classes, @default_ns ) ->
  toString: ->
    id = if @id? then ('#' + @id ) else ''
    clz = ( '.' + c for c in ( @classes or [] ) ).join ''
    "#{@ns}:#{@tag}#{id}#{clz}"


class NSChangeTag
  constructor: ( @ns ) ->
  toString: -> @ns + ':'

module.exports = main = ( tags, default_ns = 'html' ) ->
  for t in tags.trim().split ' ' when t isnt ''
    head = parse_tag t.trim(), default_ns
    # if the head is a namespace change we inherit it
    default_ns = head.ns if head instanceof NSChangeTag
    head

parse_tag = ( tag, default_ns = 'html' ) ->
  
  tag = tag.trim()

  resolved_ns = default_ns
  declared_ns = undefined

  # split by ':' to find namespace
  parts = tag.split ':'
  if parts.length is 2 # it has a namespace
    resolved_ns = declared_ns = parts.shift()
    if parts[0].length is 0
      return new NSChangeTag declared_ns # just a namespace scope
  
  # parse as an HTML tag ( non strict )
  result = htp parts[0], no, no
  result.ns = declared_ns

  # some NS specific post processing
  switch resolved_ns
    when 'ext'
      # ext class names are passed with hyphens instead of dots ( so they are valid html tags )
      result.tag = result.tag.split('-').join('.')
      # the default ( no tag ) for ext is 'panel'
      result.tag = 'panel' if result.tag.toLowerCase() is 'div'
    when 'html'
      result.tag = result.tag.toLowerCase()

  new TagHead result.tag, result.ns, result.id, result.classes, default_ns


main.TagHead = TagHead
main.NSChangeTag = NSChangeTag


# casting

main.as_one_tag_head = ( v, default_ns = 'html' ) ->
  if typeof v is 'string'
    heads = main v, default_ns
    if heads.length isnt 1
      throw new Error 'err'
    else 
      return heads[0]
  else
    unless v instanceof TagHead
      throw new Error 'err'
    return v

main.as_many_tag_heads = ( v, default_ns = 'html' ) ->
  if typeof v is 'string'
    return main v, default_ns
  if v instanceof Array
    if v.length > 0
      unless v[0] instanceof TagHead
        throw new Error 'e'
    return v
  if v instanceof TagHead
    return [v]
  throw new Error 'e'


test = ->
  console.log main '#xyz a.active ext:panel#my-panel.aqua-panel'
  console.log main 'ext:'
  console.log main 'ext:Ext-Panel'
  console.log main 'div ext: panel button html: a#link ext:button'