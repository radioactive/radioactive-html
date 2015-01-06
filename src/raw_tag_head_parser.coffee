htp = require 'htmltagparser'

class TagHead
  constructor: ( @tag, @ns, @id, @classes ) ->
  toString: ->
    id = if @id? then ('#' + @id ) else ''
    clz = ( '.' + c for c in ( @classes or [] ) ).join ''
    "#{@ns}:#{@tag}#{id}#{clz}"

module.exports = main = ( tag ) ->
  return tag if tag instanceof TagHead
  unless typeof tag is 'string'
    throw new Error 'tag must be a string'
  if tag.indexOf(' ') isnt -1
    throw new Error 'Raw tag parser handles single tags only ( no spaces ) ' + tag
  tag = tag.trim()
  declared_ns = undefined
  # split by ':' to find namespace
  parts = tag.split ':'
  if parts.length is 2 # it has a namespace
    declared_ns = parts.shift()
    if parts[0].length is 0
      return new TagHead null, declared_ns
  # parse as an HTML tag ( non strict )
  result = htp parts[0], no, no
  result.ns = declared_ns
  new TagHead result.tag, result.ns, result.id, result.classes

main.TagHead = TagHead

test = ->
  console.log main '#xyz'
  console.log main 'ext:'
  console.log main 'ext:Ext-Panel'
  console.log main 'foo:a#link.active'