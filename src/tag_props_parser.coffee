ut = require 'ut'

###
Generic parsing of properties
Returns an object with

r =
  classflags: 
  styles:
  listeners:
  watchers:
  properties:
###

partition = ( str, num ) -> [str[0...num], str[num..str.length]]

module.exports = parse = ( props ) ->
  r =
    classflags: {}
    styles:     {}
    listeners:  {}
    watchers:   {}
    properties: {}
    queries:    {}
  for own k, v of props
    if k is '?' then k = '? ' # hack: we need the extra space for the split() below to work
    [first, rest] = partition k, 1
    switch first
      when '?'
        q = rest.trim()
        # the empty query is stored
        # using a special key ( since the empty string is not a valid key )
        q = '__empty__' if q.length is 0
        r.queries[q] = v
      when '.'
        r.classflags[rest] = v
      when '$'
        (r.styles ?= {})[rest] = v
      else
        if k.indexOf('on') is 0
          ( r.listeners ?= {} )[ k[2..k.length] ] = v
        else
          # it is a property or a property watcher
          if k.indexOf('$') is -1 # property
            ( r.properties ?= {} )[k] = v
          else # property watcher ( uni or bi )
            splitter = if k.indexOf('$$') is -1 then '$' else '$$'
            parts = k.split splitter
            event = parts[1]
            event = event[2..event.length] if event.indexOf('on') is 0 # remove optional on... prefix
            ( (r.watchers ?= {} )[parts[0]] ?= {} )[event] =
              handler:       v
              bidirectional: splitter is '$$'

  basic_validations r
  
  r


basic_validations = ( t ) ->

  ut.kv t.listeners, (event, handler) ->
      unless typeof handler is 'function'
        throw new Error "'#{event}' listener must be a function"

  ut.kkv t.watchers, ( prop, event, handler ) ->
        unless typeof handler.handler is 'function'
          throw new Error "watcher #{prop}$$on#{event} must be a function"

  ut.kv t.classflags, ( k, v ) ->
      # boolean or function
      tof = typeof v
      unless ( tof is 'boolean' ) or ( tof is 'function' )
        throw new Error "value for classflag '.#{k}' must be boolean or function ( that returns a boolean )"

  ut.kv t.queries, ( k, v ) ->
      unless typeof v is 'object'
        throw new Error "the content of a query tag must be an object ( query: #{k} )"





test = ->
  console.log parse
    '.class': yes
    '$style': 'style'
    'prop':   'property'
    'onclick': ->
    'prop$$event': ->

  console.log parse
    '.class': yes
    'prop$$event': ->

