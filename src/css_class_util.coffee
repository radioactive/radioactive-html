
###
returns a ( possibly reactive ) array of strings
###
css_classes = ( v ) ->
  return css_classes v() if typeof v is 'function'
  if typeof v is 'string'
    return css_classes ( c for c in v.trim().replace('.', ' ').split(' ') when c isnt '' )
  unless v instanceof Array then throw new Error ' '
  v

css_flag = ( v ) ->
  return css_flag v() if typeof v is 'function'
  not not v


css_flagged_classes = ( classes, flag ) ->
  if css_flag flag then css_classes classes else []


css_multiple_flagged_classes = ( mfc ) ->
  return css_multiple_flagged_classes mfc() if typeof mfc is 'function'
  all = []
  for x in mfc
    all = all.concat css_flagged_classes x[0], x[1]
  all


exports.mfc = css_multiple_flagged_classes

test = ->
  c = css_multiple_flagged_classes [
    [ 'a', yes ]
    [ 'b e m .ff', -> yes ]
    [ 'c', no ]
    [ ['x', 'y'], yes ]
  ]
  console.log c